---
description: Audit security risks with evidence-ranked findings
argument-hint: "[scope]"
---

Perform a read-only security audit. Primary scope: `${1:-current repository}`. Additional scope or context arguments, if any: `${@:2}`. Use a fresh `security-auditor` and add a QA or supply-chain review angle only when scope warrants it. Cover application and supply-chain risk as relevant.

Rank findings by severity, exploitability, and confidence. Include evidence, exploit preconditions, smallest remediation, and regression test for each. Distinguish confirmed findings from speculative risks. If no findings remain, report clean audit plus coverage gaps and limitations. Do not edit, stage, or commit.
