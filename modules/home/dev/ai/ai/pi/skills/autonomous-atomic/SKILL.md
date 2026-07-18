---
name: autonomous-atomic
description: Execute an explicitly invoked, scoped task with one writer, evidence-led validation, bounded review, and atomic commits.
---

# Autonomous Atomic Workflow

Use this workflow only when explicitly invoked. Invocation authorizes stated scope only; it does not grant authority beyond the request.

## Baseline

1. Read project instructions and inspect Git status, diff, relevant files, ownership, and existing patterns.
2. Preserve unrelated changes and generated conventions.
3. Stop before any target-file overlap, missing secret, or unapproved scope, product, or architecture decision. Ask for required input.
4. Selectively use an asker, searcher, built-in researcher, or architect only when task needs that role. Do not fan out by default.
5. Assign exactly one writer per worktree: either developer or devops-infra. Reviewers always remain read-only. Route every fix to the original sole writer.

## Execution

1. Define acceptance evidence before implementation: expected files, behavior, checks, and constraints.
2. Implement smallest scoped change while preserving unrelated work.
3. Run focused validation first, followed by broader relevant checks.
4. After validation, use fresh, risk-selected reviewers. Route fixes back to same writer. Stop after at most three material review-and-fix rounds; report unresolved findings instead of looping.
5. Stage only owned paths or hunks. Verify staged diff excludes unrelated work.
6. After checks pass, create task-sized Conventional Commits only.

Never push. Autonomous invocation authorizes implementation and scoped Conventional Commits only. Merge, deploy, secret rotation, reset, stash, clean, discard, and other destructive actions are outside autonomous scope. If one is encountered, stop and report or request a separate explicit user request for that exact action; do not continue it inside the autonomous workflow. Outside autonomy, perform those actions only when the user explicitly requests the exact action. Autonomous scope alone is not approval.

## Report

Report changed files, exact commands and results, commit SHAs, skipped checks with reasons, unresolved findings, and residual risks.
