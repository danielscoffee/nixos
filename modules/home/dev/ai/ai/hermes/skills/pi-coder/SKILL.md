---
name: pi-coder
description: Delegate repository implementation to existing Pi in isolated worktree
version: 1.0.0
platforms: [linux]
metadata:
  hermes:
    tags: [Development, Git, Pi, Worktrees]
    requires_toolsets: [terminal]
    requires_tools: [terminal]
---

# Pi Coder

Use Pi as sole repository implementation worker. Hermes owns task framing, review, and acceptance.

## When to use

Use for repository edits, bug fixes, refactors, tests, and scoped documentation tied to code.

Do not use for questions answerable by inspection, general research, or non-repository tasks.

## Safety contract

- Hermes native `worktree: true` provides isolated branch and checkout.
- One Pi process at a time. Never call `delegate_task` or start another coding agent.
- Pi owns project-file edits. Hermes may write only control brief, inspect files/diffs, and run validation.
- Never push, merge, deploy, publish, activate system configuration, reset, stash, clean, or discard work.
- Never place credentials or private data in task brief, prompts, command lines, logs, or commits.
- Preserve existing Pi home, auth, sessions, extensions, packages, prompts, skills, and model settings.
- Stop if source checkout was dirty before Hermes worktree began, branch state is unclear, or another worker is active.

## Procedure

### 1. Inspect before delegation

Run and review:

```text
git rev-parse --show-toplevel
git worktree list --porcelain
git status --short --branch
git log -1 --oneline
```

Identify primary checkout from worktree list, then inspect its status with `git -C <primary-checkout> status --porcelain=v1`. Stop on any output. Confirm current checkout is Hermes-created worktree, not primary checkout.

Read repository `AGENTS.md`, `.hermes.md`, README, and relevant test/build configuration. Do not infer commands that repository already documents.

### 2. Write bounded task brief

Create `.hermes-pi-task.md` in current worktree. Include:

```markdown
# Objective
<one measurable outcome>

# Repository context
- Current Hermes worktree and branch
- Relevant files and existing behavior
- Applicable AGENTS.md instructions

# Scope
- Files or subsystem allowed to change
- Explicit non-goals

# Acceptance criteria
- Observable behavior
- Required focused test
- Required broader repository check
- Clean working tree and scoped Conventional Commit

# Restrictions
- Do not edit outside current worktree
- Do not modify or commit .hermes-pi-task.md
- Do not push, merge, deploy, reset, stash, clean, or discard work
- Do not read or expose secrets
- Do not spawn subagents
- Preserve unrelated changes and generated-file conventions

# Completion report
List changed files, commit hash, exact validation commands and outcomes, then state success or failure.
```

Brief must be self-contained but small. Use repository paths, not pasted secret-bearing output.

### 3. Delegate once

Run Pi from worktree root:

```text
pi --print --name "hermes delegated implementation" "Read .hermes-pi-task.md and execute it. Follow all AGENTS.md files. Work only in this checkout. Return completion report."
```

Do not pass provider/model flags unless user requested override. Existing Pi configuration remains authority.

Wait for process to finish. A nonzero exit, timeout, missing report, or tool failure is not success.

### 4. Review and validate

Inspect evidence, never trust summary alone:

```text
git status --short --branch
git log --oneline --decorate -5
git diff --stat <base>..HEAD
git diff --check <base>..HEAD
git diff <base>..HEAD
```

Reject work when:

- task brief was committed;
- unrelated files changed;
- source checkout changed;
- worktree contains uncommitted implementation changes;
- commit is missing or unscoped;
- required validation is missing, stale, or failed;
- diff contains secrets or generated artifacts that repository does not track.

Run smallest independent check that proves acceptance criteria, then repository-required broader check. Record exact command and result.

### 5. Correction loop

When review or validation fails, update `.hermes-pi-task.md` with concrete evidence and one correction objective. Invoke same Pi command again in same worktree. Keep one worker; maximum two correction attempts unless user approves more.

Do not repair Pi's project files directly. If Pi cannot finish, preserve dirty worktree and report path, branch, failed command, and residual risk.

### 6. Finish

On acceptance:

1. Remove only `.hermes-pi-task.md`.
2. Confirm `git status --porcelain=v1` is empty.
3. Report branch, commit hash, changed files, validation evidence, and primary checkout status.
4. Exit Hermes normally. Native Hermes cleanup removes clean worktree; dirty worktree remains for recovery.

Never merge or push. User performs integration separately.
