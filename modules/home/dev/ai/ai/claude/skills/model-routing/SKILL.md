---
name: model-routing
description: Model routing for delegated work. Use before spawning a subagent, writing a workflow agent() call, or handing work to Codex; picks Haiku, Sonnet, Opus, Fable, or Codex gpt-6-astra, plus the effort level.
---

# Model routing

Route each piece of delegated work to the cheapest **tier** whose failure a check would catch. Spend capability where a wrong answer is expensive or silent.

## Tiers

| Tier | Selector | In / out per MTok | Context | Effort | Route here |
|---|---|---|---|---|---|
| Haiku 4.5 | `haiku` | $1 / $5 | 200K | `low` | Scout: locate files and symbols, read logs, run checks and report output, apply a fully specified mechanical edit, condense large tool output |
| Sonnet 5.5 | `sonnet` | $2 / $10 | 1M | `medium` | Implement a planned change, write tests, single-dimension review, most subagent work |
| Opus 5.5 | `opus` | $4 / $20 | 1M | `high` | Plan and design, bugs with no repro, NixOS/service/security changes, judge and verify stages, synthesis across agents |
| Fable 5.1 | `fable` | $10 / $50 | 1M | `high` | Hardest work: long-horizon cross-cutting changes, high-risk plans, a problem Opus missed twice, the final call on a high-stakes disagreement. Turns run long |
| Codex gpt-6-astra | `codex:codex-rescue` agent | OpenAI quota | 272K | Codex default | Cross-family: adversarial review of a Claude-built change, independent diagnosis when Claude is stuck, a second implementation to compare, bounded unattended implementation |

Prices are Claude API list prices (2026-09).

## Rules

- **Effort before tier.** For judgment-heavy work, a strong model at lower effort beats a weaker model at high effort. Drop tier only for mechanical, checkable work.
- **Escalate** one tier after a failed attempt and carry the evidence (error output, failing check, reviewer finding). Opus → Fable after two Opus misses; any tier → Codex when two Claude attempts stall on the same wall.
- **Cross-family review**: risky or large Claude-built changes get a Codex review; Codex-built changes get an Opus review.
- **One writer** per worktree. Reviewers stay read-only; fixes go back to the original writer. Parallel writers each get `isolation: "worktree"`.
- **Bounded Codex calls**: `codex:codex-rescue` makes one Bash call, so hand it work that finishes within ~10 minutes. For longer Codex work, suggest `/codex:rescue --background` to the user.

## Invocation

- Agent tool: `model: "haiku" | "sonnet" | "opus" | "fable"`; omit it to inherit the session model.
- Workflow `agent()`: `{ model, effort }`. Codex: `{ agentType: "codex:codex-rescue" }`, prompt opening with `--wait --model gpt-6-astra`, then `--write` for edits or "Read-only" for review and diagnosis. It returns Codex's raw stdout, so `schema` does not apply.
- Whole pipeline for a non-trivial change: the user runs `/routed-task <task>` (Haiku triage → Opus or Fable plan → one writer → cross-family review → Haiku verify). Args may be `{task, builder: "sonnet" | "opus" | "codex"}`.
