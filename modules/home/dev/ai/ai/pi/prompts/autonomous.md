---
description: Execute a bounded autonomous implementation workflow
argument-hint: "<scope>"
---

If `$@` is empty or whitespace, request a concrete implementation scope and stop. Until provided, do not implement, delegate, edit, stage, commit, or otherwise mutate Git.

Explicit invocation authorizes implementation only within this scope: `$@`.

Load and follow `autonomous-atomic`. Capture baseline repository state and preserve unrelated work. Before edits, state acceptance criteria and evidence needed to prove them. Clarify only unresolved blocking decisions; stop for any unapproved scope, product, architecture, security, or deployment choice.

Select only useful specialists. Assign exactly one writer. Validate changes, then use fresh risk-based reviewers and have original sole writer fix findings, for at most 3 material review rounds. Run relevant checks and create scoped Conventional Commits only after checks pass. Do not include unrelated changes.

Never push. Autonomous invocation authorizes implementation and scoped Conventional Commits only. Merge, deploy, secret rotation, reset, stash, clean, discard, and other destructive actions are outside autonomous scope. If one is encountered, stop and report or request a separate explicit user request for that exact action; do not continue it inside the autonomous workflow. Outside autonomy, perform those actions only when the user explicitly requests the exact action. Autonomous scope alone is not approval.

Return concise evidence: scope completed, files changed, checks and results, review findings resolved or open, commit SHA, and residual risks.
