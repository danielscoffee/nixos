# Pi Agent Harness Implementation Plan

> **REQUIRED SUB-SKILL:** Use the executing-plans skill to implement this plan task-by-task.

**Goal:** Build approved static, Nix-managed Pi harness with explicit autonomous workflow, specialist agents, reusable prompts, and no runtime session mining.

**Architecture:** Keep source Markdown under `modules/home/dev/ai/ai/pi/` and link every resource explicitly through Home Manager in `pi.nix`. Reuse packaged generic subagents; custom files define narrow specialists and workflow policy. All resources inherit current model settings, preserve sole-writer safety, and never push.

**Tech Stack:** Nix/Home Manager, Pi resource discovery, Agent Skills Markdown, pi-subagents agent frontmatter, Pi prompt templates, Bash validation.

**Design:** `docs/plans/2026-07-18-pi-agent-harness-design.md`

> **As-built safety:** Exactly one writer owns all edits and fixes; reviewers remain read-only. Architect, asker, searcher, QA, NixOS diagnostician, and security auditor lack shell and mutation tools. QA inspects evidence and proposes commands for the parent or sole writer; NixOS diagnostician proposes diagnostic/validation commands and never runs project commands or rebuild/switch operations. Push is forbidden. Merge, deploy, secret rotation, reset, stash, clean, discard, and other destructive actions stop autonomous execution and are outside its authority; outside autonomy, only a separate explicit user request authorizes the exact action. Autonomous mode may create scoped, validated Conventional Commits.
>
> **Commit-command gate:** Commit commands below preserve implementation history; neither this plan nor routine plan execution authorizes them. Run a commit step only when the user explicitly requests that commit or explicitly invokes autonomous mode for scope containing it. Never push.

---

### Task 1: Establish failing resource expectations

**Files:**
- Test targets: `modules/home/dev/ai/ai/pi/AGENTS.md`
- Test targets: `modules/home/dev/ai/ai/pi/agents/*.md`
- Test targets: `modules/home/dev/ai/ai/pi/prompts/*.md`
- Test targets: `modules/home/dev/ai/ai/pi/skills/**`

**Step 1: Run missing-resource assertion**

Run:

```bash
cd /home/daniel/worktrees/nixos/feat-pi-agent-harness
required=(
  modules/home/dev/ai/ai/pi/AGENTS.md
  modules/home/dev/ai/ai/pi/agents/architect.md
  modules/home/dev/ai/ai/pi/agents/asker.md
  modules/home/dev/ai/ai/pi/agents/developer.md
  modules/home/dev/ai/ai/pi/agents/devops-infra.md
  modules/home/dev/ai/ai/pi/agents/nixos-diagnostician.md
  modules/home/dev/ai/ai/pi/agents/qa.md
  modules/home/dev/ai/ai/pi/agents/searcher.md
  modules/home/dev/ai/ai/pi/agents/security-auditor.md
  modules/home/dev/ai/ai/pi/prompts/autonomous.md
  modules/home/dev/ai/ai/pi/prompts/grill.md
  modules/home/dev/ai/ai/pi/prompts/repo-health.md
  modules/home/dev/ai/ai/pi/prompts/security-audit.md
  modules/home/dev/ai/ai/pi/skills/autonomous-atomic/SKILL.md
  modules/home/dev/ai/ai/pi/skills/grill-me/SKILL.md
  modules/home/dev/ai/ai/pi/skills/grill-me/LICENSE
  modules/home/dev/ai/ai/pi/skills/nix-managed-debugging/SKILL.md
)
for path in "${required[@]}"; do test -f "$path" || { echo "missing: $path"; exit 1; }; done
```

Expected: FAIL on first missing resource.

**Step 2: Record baseline**

Run:

```bash
git status --short
git diff -- modules/home/dev/ai/ai/pi.nix
```

Expected: only planned `pi.nix` model-catalog removal is modified in worktree; no `flake.lock` change.

---

### Task 2: Add global policy and skills

**Files:**
- Create: `modules/home/dev/ai/ai/pi/AGENTS.md`
- Create: `modules/home/dev/ai/ai/pi/skills/autonomous-atomic/SKILL.md`
- Create: `modules/home/dev/ai/ai/pi/skills/grill-me/SKILL.md`
- Create: `modules/home/dev/ai/ai/pi/skills/grill-me/LICENSE`
- Create: `modules/home/dev/ai/ai/pi/skills/nix-managed-debugging/SKILL.md`

**Step 1: Create `AGENTS.md`**

Include exact global invariants:

```markdown
# Working agreement

- Respond tersely and concretely. Use numbered choices only when a decision blocks progress.
- Before editing, inspect project instructions, Git status and diff, relevant files, ownership, and existing patterns.
- Keep changes minimal and scoped. Preserve unrelated work and generated-file conventions.
- On NixOS/Home Manager, prefer declarative configuration. Check ownership before running initializers or writing dotfiles; never overwrite managed paths imperatively.
- Use current primary sources for version-sensitive APIs, packages, security guidance, and artifact provenance.
- Validate focused behavior before broader checks. Report exact commands and outcomes; never claim success without evidence.
- Never expose secrets or personal data. Never commit credentials.
- Never inspect historical Pi sessions at runtime.
- Routine requests stay parent-led and single-agent. Delegate or fan out only when explicitly requested or when a loaded workflow requires it.
- Keep exactly one writer per worktree. Reviewers always remain read-only. Route every fix to the original sole writer.
- Never push. Push is forbidden even when requested.
- Autonomous invocation authorizes implementation and scoped, validated Conventional Commits only. Merge, deploy, secret rotation, reset, stash, clean, discard, and other destructive actions are outside autonomous scope: stop and report. Outside autonomy, perform one only after a separate explicit user request for that exact action.
```

**Step 2: Vendor `grill-me`**

Create `SKILL.md` from upstream commit `733d312884b3878a9a9cff693c5886943753a741`, preserving behavior and adding source metadata:

```markdown
---
name: grill-me
description: Interview the user relentlessly about a plan or design until reaching shared understanding, resolving each branch of the decision tree. Use when user wants to stress-test a plan, get grilled on their design, or mentions "grill me".
license: MIT
metadata:
  source: https://github.com/mattpocock/skills/tree/733d312884b3878a9a9cff693c5886943753a741/skills/productivity/grill-me
---

Interview user relentlessly about every aspect of plan until shared understanding. Walk each branch of design tree, resolving dependent decisions one by one. For every question, provide recommended answer.

Ask one question at a time.

If codebase exploration can answer question, inspect code instead of asking user.
```

Copy upstream MIT license verbatim into `LICENSE`.

**Step 3: Create `autonomous-atomic` skill**

Frontmatter:

```yaml
---
name: autonomous-atomic
description: Run explicitly authorized repository work end-to-end using focused specialists, one writer, validation, review/fix loops, and task-sized commits without pushing. Use only when user invokes autonomous mode or /autonomous.
---
```

Body must define:

1. Explicit invocation is authorization only for stated scope.
2. Capture baseline Git status/diff and project instructions.
3. Stop on overlapping target-file edits, destructive operations, missing secrets, deployments, or unapproved scope/architecture/product decisions.
4. Use `asker` only for unresolved decisions; `searcher` for local evidence; builtin `researcher` for current external evidence; `architect` for cross-module design.
5. Select exactly one writer: `developer` or `devops-infra`.
6. Define acceptance evidence before implementation.
7. Run focused validation, fresh risk-selected review, same-writer fixes, and at most three material review rounds.
8. Preserve unrelated changes. Stage exact owned paths/hunks only.
9. Commit task-sized Conventional Commits only after required checks pass and the user explicitly invoked autonomous mode for that scope. The plan itself and routine execution grant no commit authority. Never push.
10. Return changed files, validation results, commit SHAs, skipped checks, and residual risks.

**Step 4: Create `nix-managed-debugging` skill**

Frontmatter:

```yaml
---
name: nix-managed-debugging
description: Diagnose NixOS and Home Manager ownership conflicts, immutable paths, activation collisions, module/config drift, and declarative validation failures. Use for Nix-managed dotfiles, read-only path errors, rebuild failures, and system integration debugging.
---
```

Body must require:

1. Reproduce or capture exact error.
2. Inspect symlink destination, `/nix/store` ownership, `home.file`, XDG configuration, and module import path before mutating.
3. Determine whether destination is Nix-managed, generated, runtime state, or unmanaged.
4. Check installed version and current primary docs for compatibility-sensitive options.
5. Fix source module rather than generated target.
6. Avoid imperative initialization into managed paths.
7. Validate smallest evaluation/build first, then wider flake checks.
8. Explain activation collision handling and rollback risk; never delete user data automatically.

**Step 5: Run skill validation**

Run:

```bash
for skill in modules/home/dev/ai/ai/pi/skills/*/SKILL.md; do
  head -n 1 "$skill" | grep -qx -- '---'
  grep -q '^name: [a-z0-9-]\+$' "$skill"
  grep -q '^description: ' "$skill"
done
grep -q '733d312884b3878a9a9cff693c5886943753a741' modules/home/dev/ai/ai/pi/skills/grill-me/SKILL.md
grep -q 'MIT License' modules/home/dev/ai/ai/pi/skills/grill-me/LICENSE
```

Expected: PASS.

**Step 6: Commit (conditional on explicit user authorization)**

```bash
git add modules/home/dev/ai/ai/pi/AGENTS.md modules/home/dev/ai/ai/pi/skills
git commit -m "feat(pi): add harness workflow skills"
```

---

### Task 3: Add specialist agents

**Files:**
- Create: `modules/home/dev/ai/ai/pi/agents/architect.md`
- Create: `modules/home/dev/ai/ai/pi/agents/asker.md`
- Create: `modules/home/dev/ai/ai/pi/agents/developer.md`
- Create: `modules/home/dev/ai/ai/pi/agents/devops-infra.md`
- Create: `modules/home/dev/ai/ai/pi/agents/nixos-diagnostician.md`
- Create: `modules/home/dev/ai/ai/pi/agents/qa.md`
- Create: `modules/home/dev/ai/ai/pi/agents/searcher.md`
- Create: `modules/home/dev/ai/ai/pi/agents/security-auditor.md`

**Step 1: Create read-only specialists**

These agents receive no shell or mutation tools: `architect`, `asker`, `searcher`, `qa`, `nixos-diagnostician`, and `security-auditor`.

Use common frontmatter defaults:

```yaml
systemPromptMode: append
inheritProjectContext: true
inheritSkills: false
defaultContext: fresh
completionGuard: false
```

Create these role contracts:

- `architect`: read/search/LSP/AST tools; inspect architecture and return context, 2-3 options, recommendation, trade-offs, migration order, validation impact, unresolved decisions. Never edit.
- `asker`: read/search tools plus `skills: grill-me`; inspect code first, resolve one decision branch at a time, and return exactly one next question with recommended answer and why it matters. Never edit.
- `searcher`: read/search/LSP/AST tools; local repository evidence only, compressed paths/symbols/data flow/ownership/tests/risks. No web research and no edits.
- `qa`: read/search/LSP/AST tools; inspect acceptance criteria and supplied validation evidence, cover regression and user-flow behavior, propose exact safe validation commands for the parent or sole writer, and report pass/fail/evidence/gaps. It does not run project commands or edit.
- `nixos-diagnostician`: read/search/web tools plus `skills: nix-managed-debugging`; diagnose NixOS/Home Manager/systemd/package ownership, identify declarative source fix, and propose diagnostic/validation commands for the parent or sole writer. It does not run project commands, rebuild/switch systems, or edit.
- `security-auditor`: read/search/LSP/AST/web tools; review application and supply-chain threats, report severity, exploit path, evidence, smallest safe remediation, and missing tests. Never edit.

Every read-only body must forbid editing, staging, committing, and other project mutation.

**Step 2: Create writer specialists**

`developer` frontmatter:

```yaml
---
name: developer
description: Sole-writer implementation executor for approved application or repository changes with minimal diffs, focused tests, validation evidence, and decision escalation.
systemPromptMode: append
inheritProjectContext: true
inheritSkills: true
defaultContext: fork
---
```

Body: implement approved scope only; inspect patterns; use TDD when behavior changes; remain sole writer; preserve unrelated changes; stop for unapproved decisions; verify; report changed files, commands/outcomes, residual risk; commit only when user explicitly invokes autonomous mode for that scope or separately requests the exact commit; never push.

`devops-infra` frontmatter follows same writer-capable defaults with description covering Nix, CI/CD, containers, releases, systemd, deployment, and supply chain. Body requires current primary docs for version-sensitive infrastructure, declarative configuration, rollback path, and sole-writer assignment before edits. Deployment and secret rotation stop autonomous execution; outside autonomy each requires a separate explicit user request for that exact action.

**Step 3: Validate agent frontmatter and boundaries**

Run:

```bash
expected='architect asker developer devops-infra nixos-diagnostician qa searcher security-auditor'
for name in $expected; do
  file="modules/home/dev/ai/ai/pi/agents/$name.md"
  test -f "$file"
  grep -q "^name: $name$" "$file"
  grep -q '^description: ' "$file"
done
for name in architect asker nixos-diagnostician qa searcher security-auditor; do
  grep -qi 'never edit\|do not edit\|read-only' "modules/home/dev/ai/ai/pi/agents/$name.md"
done
grep -q '^skills: grill-me$' modules/home/dev/ai/ai/pi/agents/asker.md
grep -q '^skills: nix-managed-debugging$' modules/home/dev/ai/ai/pi/agents/nixos-diagnostician.md
```

Expected: PASS.

**Step 4: Commit (conditional on explicit user authorization)**

```bash
git add modules/home/dev/ai/ai/pi/agents
git commit -m "feat(pi): add specialist subagents"
```

---

### Task 4: Add invocation prompts

**Files:**
- Create: `modules/home/dev/ai/ai/pi/prompts/autonomous.md`
- Create: `modules/home/dev/ai/ai/pi/prompts/grill.md`
- Create: `modules/home/dev/ai/ai/pi/prompts/repo-health.md`
- Create: `modules/home/dev/ai/ai/pi/prompts/security-audit.md`

**Step 1: Create prompts**

Use Pi prompt-template frontmatter with descriptions and argument hints.

- `/autonomous <scope>`: explicitly load/follow `autonomous-atomic`; treat `$@` as authorized implementation scope; keep exactly one writer and route every review fix back to that original writer; select only useful read-only specialists; commit atomically after validation; never push or perform dangerous actions outside autonomous scope.
- `/grill <plan-or-design>`: invoke `asker`/`grill-me` against `$@`; inspect repo before asking answerable questions; ask one question with recommendation and wait.
- `/repo-health [scope]`: read-only map using parallel `searcher` passes when useful, builtin `researcher` only for current external facts, architect synthesis, ranked findings with evidence; do not implement.
- `/security-audit [scope]`: fresh `security-auditor` plus optional QA/supply-chain angle; read-only findings ranked by severity with exploitability, evidence, remediation, and test gaps.

**Step 2: Validate prompt metadata and variables**

Run:

```bash
for prompt in modules/home/dev/ai/ai/pi/prompts/*.md; do
  head -n 1 "$prompt" | grep -qx -- '---'
  grep -q '^description: ' "$prompt"
  grep -q '\$@\|\${1:-' "$prompt"
done
```

Expected: PASS.

**Step 3: Commit (conditional on explicit user authorization)**

```bash
git add modules/home/dev/ai/ai/pi/prompts
git commit -m "feat(pi): add harness workflow prompts"
```

---

### Task 5: Link resources and remove obsolete model catalog

**Files:**
- Modify: `modules/home/dev/ai/ai/pi.nix`

**Step 1: Confirm model-catalog test is red on baseline and green in worktree**

Run:

```bash
! grep -q 'home.file.".pi/agent/models.json"' modules/home/dev/ai/ai/pi.nix
grep -q 'defaultProvider = "openai-codex";' modules/home/dev/ai/ai/pi.nix
grep -q 'defaultModel = "gpt-5.6-sol";' modules/home/dev/ai/ai/pi.nix
```

Expected: PASS in worktree after carried model-catalog removal.

**Step 2: Add explicit Home Manager links**

For every source resource, add one `home.file` entry with `force = true` and exact `source = ./pi/...`. Link targets:

```text
.pi/agent/AGENTS.md
.pi/agent/agents/architect.md
.pi/agent/agents/asker.md
.pi/agent/agents/developer.md
.pi/agent/agents/devops-infra.md
.pi/agent/agents/nixos-diagnostician.md
.pi/agent/agents/qa.md
.pi/agent/agents/searcher.md
.pi/agent/agents/security-auditor.md
.pi/agent/prompts/autonomous.md
.pi/agent/prompts/grill.md
.pi/agent/prompts/repo-health.md
.pi/agent/prompts/security-audit.md
.pi/agent/skills/autonomous-atomic/SKILL.md
.pi/agent/skills/grill-me/SKILL.md
.pi/agent/skills/grill-me/LICENSE
.pi/agent/skills/nix-managed-debugging/SKILL.md
```

Keep existing RTK extension and package settings unchanged. Keep default provider/model lines.

**Step 3: Validate every source and target appears once**

Run:

```bash
for source in \
  AGENTS.md \
  agents/{architect,asker,developer,devops-infra,nixos-diagnostician,qa,searcher,security-auditor}.md \
  prompts/{autonomous,grill,repo-health,security-audit}.md \
  skills/autonomous-atomic/SKILL.md \
  skills/grill-me/{SKILL.md,LICENSE} \
  skills/nix-managed-debugging/SKILL.md
do
  test "$(grep -Fc "./pi/$source" modules/home/dev/ai/ai/pi.nix)" -eq 1
done
```

Expected: PASS.

**Step 4: Format and evaluate**

Run:

```bash
nixfmt modules/home/dev/ai/ai/pi.nix
nix flake check --no-build
nix eval .#homeConfigurations.daniel.activationPackage.drvPath
```

Expected: all exit 0.

**Step 5: Commit (conditional on explicit user authorization)**

```bash
git add modules/home/dev/ai/ai/pi.nix
git commit -m "feat(pi): manage agent harness with Nix"
```

---

### Task 6: Build and inspect generated Home Manager resources

**Files:**
- No source changes expected.
- Temporary ignored/untracked build result: `result` (remove after inspection).

**Step 1: Build activation package**

Run:

```bash
nix build .#homeConfigurations.daniel.activationPackage
```

Expected: exit 0.

**Step 2: Inspect generated targets**

Run:

```bash
find result/home-files/.pi/agent -maxdepth 4 -type l -o -type f | sort
```

If Home Manager stores files elsewhere, inspect `result` and locate each expected target. Confirm all linked resources and existing RTK/settings files appear.

**Step 3: Check privacy and policy invariants**

Run:

```bash
! rg -n '/home/daniel/.pi/agent/sessions|sessions/--home|\.jsonl' modules/home/dev/ai/ai/pi
grep -Rqs 'Never push\|never push' modules/home/dev/ai/ai/pi
grep -Rqs 'one writer\|sole writer' modules/home/dev/ai/ai/pi
! grep -q 'home.file.".pi/agent/models.json"' modules/home/dev/ai/ai/pi.nix
```

Expected: PASS.

**Step 4: Clean build output and inspect diff**

Run:

```bash
rm -f result
git status --short
git diff --check
git log --oneline --decorate -5
git diff d0e82a2..HEAD --stat
git diff d0e82a2..HEAD
```

Expected: only design-approved files changed; no `flake.lock`, credentials, generated files, or session data.

---

### Task 7: Independent review and final validation

**Files:**
- Modify only files with accepted concrete findings.

**Step 1: Run fresh reviews**

Request fresh review angles:

1. Pi/subagent resource correctness and discovery semantics.
2. Safety, privacy, Git policy, and autonomous escalation boundaries.
3. Simplicity, duplication, wording precision, and Nix maintainability.

Reviewers inspect `git diff d0e82a2..HEAD` and always remain read-only. Route every accepted finding to the original sole writer.

**Step 2: Apply accepted fixes with original sole writer**

Route every accepted finding to the original sole writer. Make only concrete fixes inside approved design. Re-run affected assertions and Nix checks. Only with explicit user authorization (or explicitly invoked autonomous scope), commit fixes as:

```bash
git commit -m "fix(pi): harden agent harness policies"
```

Skip commit when no fixes exist.

**Step 3: Final verification**

Run:

```bash
nix flake check --no-build
nix eval .#homeConfigurations.daniel.activationPackage.drvPath
nix build .#homeConfigurations.daniel.activationPackage
rm -f result
git diff --check
git status --short
```

Expected: all checks exit 0 and worktree is clean.

**Step 4: Post-activation manual checks**

After user activates Home Manager:

```text
/reload
/subagents-doctor
```

Then verify agent list contains `architect`, `asker`, `developer`, `devops-infra`, `nixos-diagnostician`, `qa`, `searcher`, `security-auditor`, and builtin `researcher`. Smoke-test `/grill`, `/repo-health`, `/security-audit`, and `/autonomous` with read-only scopes first.
