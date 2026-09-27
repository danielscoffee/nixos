import {
	closeSync,
	constants,
	fstatSync,
	fsyncSync,
	lstatSync,
	mkdirSync,
	openSync,
	writeSync,
} from "node:fs";
import { join } from "node:path";
import {
	createProvider,
	envApiKeyAuth,
	StringEnum,
	Type,
} from "@earendil-works/pi-ai";
import {
	type ExtensionAPI,
	getAgentDir,
	truncateHead,
} from "@earendil-works/pi-coding-agent";
import type { Static } from "typebox";
import { Check } from "typebox/value";

// API contract: https://docs.typesafe.ai/api
const State = Type.Union([
	Type.String(),
	Type.Record(Type.String(), Type.Unknown()),
	Type.Array(Type.Unknown()),
]);
const Entry = Type.Union([State, Type.Null()]);
const Question = Type.Union([
	Type.Object(
		{
			type: StringEnum(["noul"] as const),
			instructions: State,
			criteria: Type.Optional(
				Type.Object(
					{
						true: Type.Optional(Entry),
						false: Type.Optional(Entry),
					},
					{ additionalProperties: false },
				),
			),
		},
		{ additionalProperties: false },
	),
	Type.Object(
		{
			type: StringEnum(["choice"] as const),
			instructions: State,
			criteria: Type.Record(Type.String(), Entry, {
				minProperties: 1,
				maxProperties: 255,
			}),
		},
		{ additionalProperties: false },
	),
	Type.Object(
		{
			type: StringEnum(["score"] as const),
			instructions: State,
			criteria: Type.Array(Entry, { minItems: 2 }),
		},
		{ additionalProperties: false },
	),
]);
const Parameters = Type.Object(
	{
		state: State,
		questions: Type.Record(Type.String(), Question, { minProperties: 1 }),
		model: Type.Optional(
			Type.String({
				minLength: 1,
				description: "Defaults to jev-latest; use a versioned ID to pin.",
			}),
		),
	},
	{ additionalProperties: false },
);

export type JevInput = Static<typeof Parameters>;

const Probability = Type.Number({ minimum: 0, maximum: 1 });
const Probabilities = Type.Record(Type.String(), Probability);
const ResponseSchema = Type.Object({
	model: Type.String(),
	answers: Type.Record(
		Type.String(),
		Type.Union([
			Type.Object({ type: StringEnum(["noul"] as const), noul: Probability }),
			Type.Object({
				type: StringEnum(["choice"] as const),
				choice: Type.String(),
				probabilities: Probabilities,
				confidence: Probability,
			}),
			Type.Object({
				type: StringEnum(["score"] as const),
				score: Type.Number(),
				legend: Type.Record(Type.String(), Entry),
				probabilities: Probabilities,
				confidence: Probability,
			}),
		]),
	),
	usage: Type.Object({
		input_tokens: Type.Integer({ minimum: 0 }),
		output_tokens: Type.Integer({ minimum: 0 }),
	}),
});

const FeedbackDraft = Type.Object(
	{
		model: Type.String(),
		state: State,
		question: Question,
		prediction: Type.Union([Type.String(), Type.Number()]),
	},
	{ additionalProperties: false },
);

function saveFeedback(
	sample: Static<typeof FeedbackDraft> & {
		expected: boolean | string | number;
	},
) {
	const line = Buffer.from(`${JSON.stringify(sample)}\n`);
	if (line.byteLength > 50 * 1024) throw new Error("Feedback exceeds 50 KiB");
	const agentDir = getAgentDir();
	const root = lstatSync(agentDir);
	if (
		!root.isDirectory() ||
		root.uid !== process.getuid?.() ||
		root.mode & 0o022
	) {
		throw new Error("Unsafe agent directory");
	}
	const directory = join(agentDir, "jev-feedback");
	try {
		mkdirSync(directory, { mode: 0o700 });
	} catch (error) {
		if ((error as NodeJS.ErrnoException).code !== "EEXIST") throw error;
	}
	const parent = lstatSync(directory);
	if (
		!parent.isDirectory() ||
		parent.uid !== process.getuid?.() ||
		parent.mode & 0o077
	) {
		throw new Error("Unsafe feedback directory");
	}
	const file = openSync(
		join(directory, "samples.jsonl"),
		constants.O_WRONLY |
			constants.O_APPEND |
			constants.O_CREAT |
			constants.O_NOFOLLOW |
			constants.O_NONBLOCK,
		0o600,
	);
	try {
		const stat = fstatSync(file);
		if (
			!stat.isFile() ||
			stat.nlink !== 1 ||
			stat.uid !== process.getuid?.() ||
			stat.mode & 0o077
		) {
			throw new Error("Unsafe feedback file");
		}
		// One bounded O_APPEND write per record, including across Pi processes.
		if (writeSync(file, line) !== line.byteLength)
			throw new Error("Incomplete feedback write");
		fsyncSync(file);
	} finally {
		closeSync(file);
	}
}

export default function (pi: ExtensionAPI) {
	// ponytail: latest call only; add a bounded queue if older calls need feedback.
	let latest:
		| { input: JevInput; response: Static<typeof ResponseSchema> }
		| undefined;
	let reviewing = false;
	let epoch = 0;
	const clearLatest = () => {
		latest = undefined;
		epoch++;
	};
	pi.on("session_start", clearLatest);
	pi.on("session_shutdown", clearLatest);
	pi.on("session_tree", clearLatest);

	pi.registerCommand("jev-feedback", {
		description:
			"Review/redact and label one question from the latest Jev call; save locally only",
		handler: async (args, ctx) => {
			if (!ctx.hasUI || args.trim()) {
				ctx.ui.notify(
					"Use /jev-feedback without arguments in an interactive session.",
					"warning",
				);
				return;
			}
			if (reviewing) {
				ctx.ui.notify("A Jev feedback review is already open.", "warning");
				return;
			}
			const recent = latest;
			if (!recent) {
				ctx.ui.notify(
					"No recent successful Jev call. Run jev first; session history is never read.",
					"warning",
				);
				return;
			}
			reviewing = true;
			try {
				const ids = Object.keys(recent.input.questions);
				const names = ids.map((id) => JSON.stringify(id));
				const index =
					ids.length === 1
						? 0
						: names.indexOf(
								(await ctx.ui.select("Jev question to label", names)) ?? "",
							);
				if (index < 0) return;
				const id = ids[index];
				const question = recent.input.questions[id];
				const answer = recent.response.answers[id];
				const text = JSON.stringify(
					{
						model: recent.response.model,
						state: recent.input.state,
						question,
						prediction:
							answer.type === "noul"
								? answer.noul
								: answer.type === "choice"
									? answer.choice
									: answer.score,
					},
					null,
					2,
				);
				if (truncateHead(text).truncated) {
					ctx.ui.notify(
						"Feedback sample too large (50 KiB / 2000 lines). Use a smaller Jev call.",
						"warning",
					);
					return;
				}
				const edited = await ctx.ui.editor(
					"Redact secrets and personal data from every field; preserve meaning",
					text,
				);
				if (edited === undefined) return;
				let draft: unknown;
				try {
					if (!truncateHead(edited).truncated) draft = JSON.parse(edited);
				} catch {
					/* Rejected below without echoing input. */
				}
				if (
					!Check(FeedbackDraft, draft) ||
					draft.model !== recent.response.model ||
					draft.question.type !== question.type
				) {
					ctx.ui.notify(
						"Invalid feedback JSON. Keep the model and question type; use only the displayed fields within 50 KiB / 2000 lines.",
						"error",
					);
					return;
				}
				const q = draft.question;
				const prediction = draft.prediction;
				const valid =
					q.type === "choice"
						? typeof prediction === "string" &&
							Object.hasOwn(q.criteria, prediction)
						: typeof prediction === "number" &&
							prediction >= 0 &&
							prediction <= (q.type === "noul" ? 1 : q.criteria.length - 1);
				if (!valid) {
					ctx.ui.notify(
						"Prediction must match the question's choices or numeric range.",
						"error",
					);
					return;
				}
				const values: (boolean | string | number)[] =
					q.type === "noul"
						? [false, true]
						: q.type === "choice"
							? Object.keys(q.criteria)
							: q.criteria.map((_, i) => i);
				const options = values.map((value, i) =>
					q.type === "score"
						? `${value}: ${JSON.stringify(q.criteria[i])}`
						: JSON.stringify(value),
				);
				const selected = options.indexOf(
					(await ctx.ui.select(
						"Correct answer (confirm or correct Jev)",
						options,
					)) ?? "",
				);
				if (selected < 0) return;
				if (
					!(await ctx.ui.confirm(
						"Save Jev feedback locally?",
						"Confirm you removed ALL secrets, credentials, and personal data from every field. " +
							"Save this reviewed sample and your label to the private jev-feedback/samples.jsonl in Pi's agent directory? " +
							"No upload, automatic retrieval, or training.",
					))
				)
					return;
				if (latest !== recent) {
					ctx.ui.notify(
						"Recent call or session changed during review. Nothing saved; run /jev-feedback again.",
						"warning",
					);
					return;
				}
				saveFeedback({ ...draft, expected: values[selected] });
				ctx.ui.notify(
					"Saved one local sample in jev-feedback/samples.jsonl. Nothing uploaded.",
					"info",
				);
			} catch {
				ctx.ui.notify(
					"Feedback save not confirmed. Check local storage before retrying. Symlinks, shared files, and non-private permissions are refused.",
					"error",
				);
			} finally {
				reviewing = false;
			}
		},
	});
	pi.registerProvider(
		createProvider({
			id: "typesafe-ai",
			name: "TypeSafe (Jev)",
			auth: { apiKey: envApiKeyAuth("TypeSafe API key", ["TYPESAFE_API_KEY"]) },
			// Native login entry; evaluations use the tool, not a chat transport.
			models: [],
			api: {},
		}),
	);
	pi.registerTool({
		name: "jev",
		label: "Jev",
		description:
			"Ask TypeSafe Jev typed questions over supplied state. Sends state/questions to api.typesafe.ai. " +
			"Noul returns P(yes); Choice selects from a criteria object; Score rates ordered criteria levels. " +
			"Batch independent questions in one call. Authenticate with /login typesafe-ai or TYPESAFE_API_KEY. " +
			"Responses above 50 KiB or 2000 lines are rejected; split large batches. No automatic retries.",
		promptSnippet:
			"Ask Jev for typed semantic judgments and probabilities, not generated text",
		promptGuidelines: [
			"Use jev only for requested semantic judgments. Never send secrets or unrelated session/file contents to jev. " +
				"Jev probabilities are not permission to act; keep policy and execution in code.",
		],
		parameters: Parameters,
		async execute(_toolCallId, params, signal, _onUpdate, ctx) {
			const callEpoch = epoch;
			if (!Check(Parameters, params)) {
				throw new Error(
					"Invalid Jev input: supply state and at least one typed question.",
				);
			}
			const apiKey = (
				await ctx.modelRegistry.getApiKeyForProvider("typesafe-ai")
			)?.trim();
			if (!apiKey) {
				throw new Error(
					"Run /login typesafe-ai and enter your API key in the secret prompt, or set TYPESAFE_API_KEY before starting Pi. Do not paste the key into chat.",
				);
			}
			const timeout = AbortSignal.timeout(30_000);
			const requestSignal = signal
				? AbortSignal.any([signal, timeout])
				: timeout;
			let response: Response;
			let data: unknown;
			try {
				requestSignal.throwIfAborted();
				response = await fetch("https://api.typesafe.ai/v1/systemone", {
					method: "POST",
					redirect: "error",
					headers: {
						Authorization: `Bearer ${apiKey}`,
						"Content-Type": "application/json",
					},
					body: JSON.stringify({
						...params,
						model: params.model ?? "jev-latest",
					}),
					signal: requestSignal,
				});
				if (response.ok) data = await response.json();
				else await response.body?.cancel();
			} catch {
				// Never expose upstream bodies or transport errors: they can contain sensitive data.
				if (requestSignal.aborted) {
					throw new Error(
						signal?.aborted
							? "Jev request cancelled."
							: "Jev request timed out.",
					);
				}
				throw new Error(
					"Jev request failed: network error or invalid JSON response.",
				);
			}
			if (!response.ok) {
				throw new Error(
					`Jev API returned HTTP ${response.status}. Check your key, request, or account limits; wait before retrying rate limits.`,
				);
			}
			if (
				!Check(ResponseSchema, data) ||
				Object.entries(params.questions).some(
					([id, question]) => data.answers[id]?.type !== question.type,
				)
			) {
				throw new Error(
					"Invalid Jev response: expected typed answers for every question and token usage.",
				);
			}
			const text = JSON.stringify(data, null, 2);
			if (truncateHead(text).truncated) {
				throw new Error(
					"Jev response too large (50 KiB / 2000 lines). Split questions into smaller batches.",
				);
			}
			if (ctx.hasUI && callEpoch === epoch) {
				latest = structuredClone({ input: params, response: data });
			}
			return { content: [{ type: "text", text }], details: data };
		},
	});
}
