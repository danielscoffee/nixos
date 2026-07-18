---
description: Execute a bounded autonomous implementation workflow
argument-hint: "<scope>"
---

If `$@` is empty or whitespace, request a concrete implementation scope and stop. Until provided, do not implement, delegate, edit, stage, commit, or otherwise mutate Git.

Explicit invocation authorizes implementation only within this scope: `$@`.

Load and follow `autonomous-atomic`. Capture baseline repository state and preserve unrelated work. Before edits, state acceptance criteria and evidence needed to prove them. Clarify only unresolved blocking decisions; stop for any unapproved scope, product, architecture, security, or deployment choice.

Select only useful specialists. Assign exactly one writer. Validate changes, then use fresh risk-based reviewers and have same writer fix findings, for at most 3 material review rounds. Run relevant checks and create scoped Conventional Commits only after checks pass. Never push, merge, deploy, use destructive Git, or include unrelated changes.

Return concise evidence: scope completed, files changed, checks and results, review findings resolved or open, commit SHA, and residual risks.
