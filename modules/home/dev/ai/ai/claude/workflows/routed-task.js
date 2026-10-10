export const meta = {
  name: 'routed-task',
  description:
    'Route a code change across Haiku, Sonnet, Opus, Fable and Codex gpt-6-astra: triage, plan, build, cross-review, verify',
  whenToUse:
    'A non-trivial change where a plan, one writer, and independent Claude + Codex review are worth extra agents. Args: task string, or {task, builder: "sonnet" | "opus" | "codex"}.',
  phases: [
    { title: 'Triage', detail: 'scope, files, risk, checks', model: 'haiku' },
    { title: 'Plan', detail: 'opus; fable when risk is high or the change is large' },
    { title: 'Build', detail: 'one writer: sonnet, opus, or Codex gpt-6-astra' },
    { title: 'Review', detail: 'read-only, cross-family: opus + Codex (+ fable on high risk)' },
    { title: 'Fix', detail: 'blocking findings go back to the same writer' },
    { title: 'Verify', detail: 'run the checks and report output', model: 'haiku' },
  ],
}

const CODEX_MODEL = 'gpt-6-astra'
const CODEX_AGENT = 'codex:codex-rescue'
const BUILDERS = ['sonnet', 'opus', 'codex']
const MAX_FIX_ROUNDS = 2
const READ_ONLY = 'Read-only: inspect with git, rg, fd and file reads; leave every file unchanged.'

const input = typeof args === 'string' ? { task: args } : args || {}
const task = String(input.task || '').trim()
if (!task) throw new Error('routed-task needs a task: pass args as a string or {task, builder}')

const str = { type: 'string' }
const strList = { type: 'array', items: str }
const oneOf = (...values) => ({ type: 'string', enum: values })
const object = (properties) => ({ type: 'object', properties, required: Object.keys(properties) })

const TRIAGE = object({
  summary: str,
  kind: oneOf('change', 'question'),
  size: oneOf('trivial', 'small', 'medium', 'large'),
  risk: oneOf('low', 'medium', 'high'),
  riskReasons: strList,
  files: strList,
  baselineDirty: strList,
  checks: strList,
  builder: oneOf(...BUILDERS),
  builderReason: str,
  blockers: strList,
})
const PLAN = object({ steps: strList, files: strList, acceptance: strList, checks: strList, risks: strList, blockers: strList })
const BUILD = object({
  summary: str,
  changedFiles: strList,
  checksRun: { type: 'array', items: object({ command: str, passed: { type: 'boolean' }, output: str }) },
  notes: strList,
})
const FINDINGS = object({
  findings: {
    type: 'array',
    items: object({ severity: oneOf('blocking', 'minor'), file: str, line: { type: 'integer' }, issue: str, fix: str }),
  },
})
const VERIFY = object({
  results: { type: 'array', items: object({ command: str, exitCode: { type: 'integer' }, outputTail: str }) },
  allPassed: { type: 'boolean' },
})

phase('Triage')
const triage = await agent(
  `Triage this task for a routed multi-agent run. ${READ_ONLY}

Task: ${task}

Fill every field:
- kind: "question" when the task asks for an answer rather than a change.
- size: trivial = one obvious edit; small = one file or a few lines; medium = several files; large = cross-cutting or a new subsystem.
- risk: high when it touches auth, secrets, prod or system config (NixOS modules, services, networking), data migrations, or concurrency; say why in riskReasons.
- files: paths the change will likely touch.
- baselineDirty: paths from \`git status --short\` before any work, so reviewers can separate pre-existing edits.
- checks: non-mutating verification commands that fit the repo (tests, linters, \`nix flake check\`, \`nix build\`, \`nixos-rebuild dry-build\`).
- builder: "codex" for a self-contained small or medium implementation that can run unattended; "opus" when correctness hinges on subtle reasoning (Nix module semantics, concurrency, security); "sonnet" for the rest.
- blockers: decisions only the user can make (secrets, credentials, prod config, product scope); empty when none.`,
  { label: 'triage', phase: 'Triage', model: 'haiku', effort: 'low', schema: TRIAGE },
)
if (!triage) throw new Error('triage agent failed')
if (triage.kind === 'question') return { status: 'not-a-change', note: 'Answer inline; routed-task is for changes.', triage }
if (triage.blockers.length) return { status: 'blocked', blockers: triage.blockers, triage }

let plan = null
let planModel = null
if (triage.size !== 'trivial') {
  planModel = triage.risk === 'high' || triage.size === 'large' ? 'fable' : 'opus'
  phase('Plan')
  plan = await agent(
    `Plan this change for a single implementing agent. ${READ_ONLY}

Task: ${task}
Triage: ${JSON.stringify(triage)}

Steps are ordered and each names its files. Acceptance criteria are observable (a command result, a behavior). Checks are non-mutating commands. Blockers are decisions only the user can make.`,
    { label: `plan:${planModel}`, phase: 'Plan', model: planModel, effort: 'high', schema: PLAN },
  )
  if (!plan) throw new Error(`plan agent (${planModel}) failed`)
  if (plan.blockers.length) return { status: 'blocked', blockers: plan.blockers, triage, plan }
}

let builder = BUILDERS.includes(input.builder) ? input.builder : triage.builder
if (builder === 'codex' && triage.size === 'large' && input.builder !== 'codex') {
  log('large change: building with opus, since each Codex stage is one bounded call')
  builder = 'opus'
}

const spec = plan
  ? `Plan steps:\n${plan.steps.map((s, i) => `${i + 1}. ${s}`).join('\n')}\nAcceptance:\n${plan.acceptance.map((a) => `- ${a}`).join('\n')}`
  : `Expected files: ${triage.files.join(', ') || 'unknown'}`
const checks = [...new Set([...(plan ? plan.checks : []), ...triage.checks])]
const baseline = triage.baselineDirty.join(', ') || 'none'

function write(extra, round) {
  const brief = `You are the sole writer for this change. Task: ${task}

${spec}

Make the smallest correct diff. Files already modified before this run (keep their unrelated edits intact): ${baseline}. Leave changes uncommitted. Run the focused checks that apply: ${checks.join('; ') || 'none listed'}.${extra ? `\n\n${extra}` : ''}`
  const opts = { label: `${round ? `fix${round}` : 'build'}:${builder}`, phase: round ? 'Fix' : 'Build' }
  if (builder === 'codex') {
    return agent(`--wait --write --model ${CODEX_MODEL} ${round ? '--resume' : '--fresh'} ${brief}`, { ...opts, agentType: CODEX_AGENT })
  }
  return agent(`${brief}\n\nReport changed files and each check you ran with its result.`, {
    ...opts,
    model: builder,
    effort: builder === 'opus' ? 'high' : 'medium',
    schema: BUILD,
  })
}

const reviewBrief = `Review the uncommitted change for this task. ${READ_ONLY}

Task: ${task}
${spec}
Files modified before this run (judge only the new edits in them): ${baseline}

Inspect \`git diff\` and \`git status --short\`. Report bugs, regressions, unmet acceptance criteria, security or destructive-operation risks, and needless scope. Blocking = must fix before merge; minor = worth noting.`

function review(reviewer, round) {
  const opts = { label: `review${round || ''}:${reviewer.name}`, phase: 'Review' }
  if (reviewer.name === 'codex') {
    return agent(
      `--wait --fresh --model ${CODEX_MODEL} Read-only review, no edits. ${reviewBrief}\n\nEnd with exactly one line: VERDICT: BLOCKING or VERDICT: OK.`,
      { ...opts, agentType: CODEX_AGENT },
    ).then((text) => (text ? { reviewer: 'codex', blocking: /VERDICT:\s*BLOCKING/i.test(text), report: text } : null))
  }
  return agent(reviewBrief, { ...opts, model: reviewer.model, effort: 'high', schema: FINDINGS }).then((res) =>
    res ? { reviewer: reviewer.name, blocking: res.findings.some((f) => f.severity === 'blocking'), report: res.findings } : null,
  )
}

phase('Build')
const build = await write('', 0)
if (!build) throw new Error(`build agent (${builder}) failed`)

const reviewers = [{ name: 'opus', model: 'opus' }]
if (builder !== 'codex') reviewers.push({ name: 'codex' })
if (triage.risk === 'high') reviewers.push({ name: 'fable', model: 'fable' })
const skipReview = triage.size === 'trivial' && triage.risk === 'low'

let reviews = []
const fixes = []
if (skipReview) {
  log('trivial low-risk change: skipping review')
} else {
  phase('Review')
  reviews = (await parallel(reviewers.map((r) => () => review(r, 0)))).filter(Boolean)
  for (let round = 1; round <= MAX_FIX_ROUNDS; round++) {
    const blocking = reviews.filter((r) => r.blocking)
    if (!blocking.length) break
    phase('Fix')
    const fix = await write(
      `Reviewers flagged blocking issues. Fix each one, or explain why it is not a defect:\n${JSON.stringify(
        blocking.map((b) => ({ reviewer: b.reviewer, report: b.report })),
        null,
        2,
      )}`,
      round,
    )
    fixes.push(fix)
    if (!fix) break
    phase('Review')
    const again = await parallel(blocking.map((b) => () => review(reviewers.find((r) => r.name === b.reviewer), round)))
    reviews = reviews.filter((r) => !r.blocking).concat(again.filter(Boolean))
  }
}
const unresolved = reviews.filter((r) => r.blocking).map((r) => r.reviewer)
if (unresolved.length) log(`blocking findings remain from: ${unresolved.join(', ')}`)

phase('Verify')
let verify = null
if (checks.length) {
  verify = await agent(
    `Run each command below from the repo root, in order, exactly as written, and report its exit code and the last 30 lines of output. Report results only; leave the code as it is.\n\n${checks.map((c) => `- ${c}`).join('\n')}`,
    { label: 'verify', phase: 'Verify', model: 'haiku', effort: 'low', schema: VERIFY },
  )
} else {
  log('no checks found: verification skipped')
}

const codexLabel = (name) => (name === 'codex' ? `codex:${CODEX_MODEL}` : name)
return {
  status: unresolved.length ? 'needs-attention' : !verify ? 'unverified' : verify.allPassed ? 'done' : 'checks-failing',
  routing: {
    triage: 'haiku',
    plan: planModel,
    builder: codexLabel(builder),
    reviewers: skipReview ? [] : reviewers.map((r) => codexLabel(r.name)),
    verify: verify ? 'haiku' : null,
  },
  triage,
  plan,
  build,
  fixes,
  reviews,
  unresolved,
  verify,
}
