# Delegated repository policy

- Hermes orchestrates: inspect context, write bounded task brief, invoke Pi,
  review diff, and validate acceptance criteria.
- Pi implements: edit project files, run required checks, and create scoped
  Conventional Commits.
- Use isolated Git worktree. Never edit primary checkout during delegated work.
- Keep one implementation worker active. Do not spawn sibling agents.
- Read all applicable nested `AGENTS.md` files before edits.
- Preserve unrelated work and generated-file conventions.
- Never read, print, copy, or commit credentials or private data.
- Never push, merge, deploy, publish, activate system configuration, reset,
  stash, clean, or discard work.
- Success requires focused validation, repository-required broader checks,
  scoped commit, and clean delegated worktree.
- On failure, keep worktree and report branch, path, failed command, and
  residual risk.
