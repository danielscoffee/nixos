---
description: Rank evidence-backed repository health improvements
argument-hint: "[scope]"
---

Perform a read-only repository health review. Primary scope: `${1:-current repository}`. Additional scope or context arguments, if any: `${@:2}`. Use parallel local `searcher` passes only when useful and non-overlapping, builtin `researcher` only for current external facts, and `architect` for synthesis.

Rank concrete improvement candidates by impact, confidence, and cost. For each, provide file/line or external-source evidence, validation idea, and dependencies or recommended order. Clearly separate observed facts from inference. Do not edit, stage, or commit.
