---
description: Pressure-test a plan or design one decision at a time
argument-hint: "<plan-or-design>"
---

If `$@` is empty or whitespace, ask user for a plan or design and stop. Do not inspect, interrogate, delegate, or implement without a target.

Use `asker` with grill-me behavior to pressure-test `$@`. Inspect repository first and answer every code-discoverable question yourself. Ask exactly one decision question at a time, including recommended answer and rationale. Wait for user response before exploring next branch. Do not implement, edit, stage, or commit.
