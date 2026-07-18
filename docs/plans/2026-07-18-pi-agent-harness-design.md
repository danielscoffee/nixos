# Nix-managed Pi agent harness design

## Goal

Create static, Nix-managed Pi harness distilled once from local session patterns. Keep routine work lean while exposing explicit autonomous workflows and focused specialists. Historical sessions never become runtime inputs.

## Decisions

- Store editable source files under `modules/home/dev/ai/ai/pi/`.
- Link each resource explicitly with Home Manager. Do not own whole Pi resource directories.
- Keep normal requests parent-led and single-agent.
- Allow autonomous workflows only after explicit invocation.
- Autonomous workflows may create task-sized Conventional Commits but never push.
- Preserve unrelated dirty-tree changes. Stop when target files contain overlapping user edits.
- Use current Pi model for every agent; no model router or per-agent model pinning.
- Keep existing packaged agents and workflows. Add specialists instead of replacing Pi packages.
- Use session history only for this design distillation. Store no session path, raw prompt, index, or runtime memory feature.

## Resources

```text
modules/home/dev/ai/ai/pi/
├── AGENTS.md
├── agents/
│   ├── architect.md
│   ├── asker.md
│   ├── developer.md
│   ├── devops-infra.md
│   ├── nixos-diagnostician.md
│   ├── qa.md
│   ├── searcher.md
│   └── security-auditor.md
├── prompts/
│   ├── autonomous.md
│   ├── grill.md
│   ├── repo-health.md
│   └── security-audit.md
└── skills/
    ├── autonomous-atomic/SKILL.md
    ├── grill-me/
    │   ├── LICENSE
    │   └── SKILL.md
    └── nix-managed-debugging/SKILL.md
```

Existing builtin `researcher` remains external-evidence specialist. Existing `scout`, `planner`, `worker`, `reviewer`, `context-builder`, `oracle`, and `delegate` remain available.

## Global policy

`AGENTS.md` stays short:

- Respond tersely and concretely.
- Inspect project instructions, Git state, ownership, relevant files, and existing patterns before edits.
- Prefer declarative NixOS/Home Manager configuration and avoid imperative writes to managed paths.
- Keep diffs scoped and preserve unrelated work.
- Use current primary sources for version-sensitive, security, package, and provenance claims.
- Validate before completion and report exact commands and outcomes.
- Never expose or commit secrets.
- Do not inspect historical sessions at runtime.
- Use exactly one writer per worktree. Reviewers always remain read-only; route every fix to the original sole writer.
- Never push. Push is forbidden even when requested.
- Merge, deploy, secret rotation, reset, stash, clean, discard, and other destructive actions are outside autonomous scope. Stop and report when one is encountered. Outside autonomy, perform one only after a separate explicit user request for that exact action.

## Specialists

`architect`, `asker`, `searcher`, `qa`, `nixos-diagnostician`, and `security-auditor` receive no shell or mutation tools.

- `architect`: read-only system boundaries, options, trade-offs, migration sequencing, and ADR-ready decisions.
- `asker`: one-question-at-a-time design interrogation using `grill-me`; supplies recommended answer and inspects code instead of asking questions code can answer.
- `searcher`: fast local-only symbol, ownership, integration-point, and pattern discovery.
- Builtin `researcher`: external primary-source research and provenance.
- `qa`: read-only test strategy, regression risks, user-flow validation, and evidence gaps. It inspects supplied evidence and proposes exact validation commands for the parent or sole writer; it does not run project commands.
- `devops-infra`: Nix, CI/CD, containers, releases, systemd, deployment, and supply-chain configuration. It writes only when assigned sole-writer responsibility.
- `developer`: implementation/execution for approved scope, focused tests, minimal diffs, verification, and optional autonomous atomic commits.
- `nixos-diagnostician`: read-only NixOS/Home Manager troubleshooting and declarative fix-location guidance. It proposes diagnostic and validation commands for the parent or sole writer; it does not run project commands or rebuild/switch systems.
- `security-auditor`: read-only application and supply-chain review with ranked evidence-backed findings.

## Grill-me source

Vendor `grill-me` from Matt Pocock's MIT-licensed skills repository at commit `733d312884b3878a9a9cff693c5886943753a741`:

- Source: <https://github.com/mattpocock/skills/tree/733d312884b3878a9a9cff693c5886943753a741/skills/productivity/grill-me>
- Behavior: ask one question at a time, include recommended answer, walk dependent decisions, and inspect code when it can answer the question.
- Include upstream MIT license.

## Workflow

Routine requests use no automatic fanout. `/autonomous <scope>` authorizes:

1. Capture Git baseline and restate exact scope.
2. Use `asker` only for unresolved decisions.
3. Gather local evidence with `searcher` and external evidence with builtin `researcher` when needed.
4. Use `architect` for cross-module design decisions.
5. Assign one writer: usually `developer`, or `devops-infra` for infrastructure-only work.
6. Run focused checks.
7. Select fresh read-only reviewers by risk: `qa`, `security-auditor`, `nixos-diagnostician`, or generic reviewer.
8. Return every accepted finding to the original sole writer. Reviewers always remain read-only.
9. Re-review material fixes, capped at three rounds.
10. Create scoped, validated Conventional Commits and report SHAs. Never push.

`/repo-health [scope]` performs read-only repository mapping and ranked recommendations. `/security-audit [scope]` performs focused security review. `/grill <plan>` starts design interrogation.

## Error handling and safety

- Preserve unrelated dirty-tree files and exclude them from staging.
- Stop if target files contain overlapping user edits.
- Never push. Push is forbidden even when requested.
- Merge, deploy, secret rotation, reset, stash, clean, discard, overwrite, and other destructive actions are outside autonomous scope: stop and report. Outside autonomy, only a separate explicit user request for the exact action authorizes it.
- Failed required validation blocks autonomous commits unless user accepts risk.
- Stop for scope expansion or unapproved product, architecture, security, or deployment decisions.
- Reviews report concrete findings with severity and file/line evidence; speculative polish stays out.
- Completion reports changed files, commands, outcomes, commit SHAs, skipped checks, and residual risks.

## Validation

1. Format and parse Nix.
2. Evaluate `homeConfigurations.daniel.activationPackage`.
3. Build Home Manager activation package when feasible.
4. Inspect generated resource targets and Markdown/YAML frontmatter.
5. Confirm resource files contain no historical-session paths or raw session data.
6. Confirm obsolete explicit GPT-5.6 Sol model catalog is absent while default provider/model settings remain.
7. Review Git diff and preserve existing `flake.lock` changes.
8. After activation, run `/reload`, `/subagents-doctor`, and agent discovery.
9. Smoke-test `/grill`, `/repo-health`, `/security-audit`, and `/autonomous` without destructive actions or pushes.

## Non-goals

- Runtime session mining, embeddings, personalization daemon, or telemetry.
- Always-on autonomy or reviewer fanout.
- Pushes, PR creation, autonomous merge/deployment/secret operations, or other destructive repository operations.
- Parallel writers in one worktree.
- Replacement of packaged generic agents.
- Model routing based on historical sessions.
- New Pi extension or standalone npm package.
