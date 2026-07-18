# Pi Plugin Update Implementation Plan

> **REQUIRED SUB-SKILL:** Use the executing-plans skill to implement this plan task-by-task.

**Goal:** Update exact Nix-managed Pi package pins and add official Ponytail plus advisor without enabling advisor or changing model defaults.

**Architecture:** Modify `programs.pi-coding-agent.settings.packages` and add one explicit Lens skills path in `pi.nix`. Resolve and inspect exact npm packages in an isolated temporary agent directory, then validate the generated Home Manager settings and Pi resource discovery.

**Tech Stack:** Nix/Home Manager, Pi 0.80.x package loader, npm registry, Node/Bun.

**Design:** `docs/plans/2026-07-18-pi-plugin-update-design.md`

**Git authorization:** Commit steps require explicit user authorization. User selected same-session planned execution; this authorizes listed scoped local commits only. Never push.

---

### Task 1: Update exact package pins

**Files:**
- Modify: `modules/home/dev/ai/ai/pi.nix`

**Step 1: Verify RED expectations**

Run assertions proving the compatibility rollback does not yet match the final target:

```bash
grep -q 'npm:pi-lens@3.8.50' modules/home/dev/ai/ai/pi.nix
! grep -q 'npm:pi-lens@3.8.70' modules/home/dev/ai/ai/pi.nix
! grep -q 'npm/node_modules/pi-lens/skills' modules/home/dev/ai/ai/pi.nix
```

Expected: all exit 0 because 3.8.50 is pinned and the 3.8.70 pin plus workaround are absent.

**Step 2: Replace package list with exact pins**

Keep current order for existing packages and append Ponytail/advisor:

```nix
packages = [
  "npm:pi-caveman@1.0.7"
  "npm:pi-superpowers@0.2.0"
  "npm:pi-web-access@0.13.0"
  "npm:pi-subagents@0.35.1"
  "npm:pi-lens@3.8.70"
  "npm:pi-powerline-footer@0.7.0"
  "npm:@ayulab/pi-rewind@0.4.6"
  "npm:@dietrichgebert/ponytail@4.8.4"
  "npm:pi-advisor@0.3.0"
];

skills = [ "npm/node_modules/pi-lens/skills" ];
```

Do not change default provider/model, resource links, extension source, `extraPackages`, or `flake.lock`.

Compatibility workaround: `pi-lens` 3.8.70 ships four skills but declares `pi.skills` as `../../skills`; Pi 0.80.8 silently discovers zero Lens skills through the package manifest. The explicit settings path exposes four new prefixed skill names: `pi-lens-ast-grep`, `pi-lens-lsp-navigation`, `pi-lens-write-ast-grep-rule`, and `pi-lens-write-tree-sitter-rule`. Remove the path only after an upstream manifest fix and resource-loader validation of all four skills.

Lifecycle rationale: 3.8.50 runs a consumer `postinstall` that downloads 26 WASM files without integrity verification. Version 3.8.70 ships npm-integrity-covered grammars and has no consumer `install` or `postinstall` hook.

**Step 3: Run focused GREEN checks**

```bash
for spec in \
  'npm:pi-caveman@1.0.7' \
  'npm:pi-superpowers@0.2.0' \
  'npm:pi-web-access@0.13.0' \
  'npm:pi-subagents@0.35.1' \
  'npm:pi-lens@3.8.70' \
  'npm:pi-powerline-footer@0.7.0' \
  'npm:@ayulab/pi-rewind@0.4.6' \
  'npm:@dietrichgebert/ponytail@4.8.4' \
  'npm:pi-advisor@0.3.0'
do
  test "$(grep -Fc "\"$spec\"" modules/home/dev/ai/ai/pi.nix)" -eq 1
done
test "$(grep -Fc '"npm/node_modules/pi-lens/skills"' modules/home/dev/ai/ai/pi.nix)" -eq 1
nixfmt modules/home/dev/ai/ai/pi.nix
git diff --check
```

Expected: all exit 0.

**Step 4: Commit**

```bash
git add modules/home/dev/ai/ai/pi.nix
git commit -m "fix(pi): load updated Lens skills"
```

---

### Task 2: Validate registry provenance and isolated package resolution

**Files:**
- No source changes.
- Temporary files only under a fresh `/tmp` directory; remove before finish.

**Step 1: Verify npm registry versions and integrity**

For each changed/new package, compare `npm view <exact-spec> version dist.integrity repository.url license` with the approved design. Expected exact versions:

```text
pi-web-access 0.13.0
pi-subagents 0.35.1
pi-lens 3.8.70
pi-powerline-footer 0.7.0
@ayulab/pi-rewind 0.4.6
@dietrichgebert/ponytail 4.8.4
pi-advisor 0.3.0
```

**Step 2: Install exact packages in isolated directory**

Hash active `~/.pi/agent/npm/package.json` and `package-lock.json` before validation. Create a temporary npm project and run `npm install --legacy-peer-deps --save-exact` with all nine package specs, without `--ignore-scripts`. Set temporary `HOME`, `XDG_CONFIG_HOME`, `PI_CODING_AGENT_DIR`, and npm cache. Never write active `~/.pi/agent`.

Expected: install exits 0 and exact direct dependencies appear in lockfile. Record npm 11 allow-scripts behavior for `@ast-grep/cli`; do not suppress its policy warning. Recheck active npm hashes after validation.

**Step 3: Audit package tree**

```bash
npm audit --omit=dev --audit-level=high
npm ls --depth=0
```

Expected: no high/critical production vulnerabilities, no deprecated installed peers, and every direct package resolved at exact target version.

**Step 4: Validate Pi manifests/resources**

Use Pi's `DefaultResourceLoader` against temporary agent settings and isolated `npm/node_modules`. Verify:

- all configured package sources resolve;
- zero package-resource diagnostics;
- harness custom agents/skills remain separate and discoverable in source validation;
- Ponytail contributes extension plus Ponytail skills;
- advisor contributes extension only;
- pi-subagents contributes bundled agents/prompts/skill;
- the explicit Lens path contributes exactly `pi-lens-ast-grep`, `pi-lens-lsp-navigation`, `pi-lens-write-ast-grep-rule`, and `pi-lens-write-tree-sitter-rule`, with zero relevant diagnostics;
- Ponytail and advisor resources load;
- advisor is not enabled and no `advisor.json` is created;
- no model call occurs;
- `scripts/rpc-load-check.mjs` or an equivalent compatible extension smoke check passes.

If full extension factory smoke-loading is safe without prompts/model calls, create and dispose an in-memory Pi session with temporary config. Otherwise report loader-only boundary explicitly.

**Step 5: Clean temporary directory**

Remove all temporary files and confirm project Git status remains clean.

---

### Task 3: Validate Home Manager generation and final diff

**Files:**
- No source changes expected.

**Step 1: Run Nix checks**

```bash
nixfmt --check modules/home/dev/ai/ai/pi.nix
nix flake check --no-build
nix eval .#homeConfigurations.daniel.activationPackage.drvPath
nix build --no-link .#homeConfigurations.daniel.activationPackage
git diff --check
```

Expected: all exit 0.

**Step 2: Inspect generated settings**

Build with a temporary out-link, locate generated `.pi/agent/settings.json`, and verify:

- package array equals exact nine-item list;
- skills array equals `["npm/node_modules/pi-lens/skills"]`;
- default provider/model remain `openai-codex` / `gpt-5.6-sol`;
- no `advisor.json` target exists;
- existing harness resources and RTK extension remain generated.

Remove temporary out-link.

**Step 3: Independent review**

Run fresh read-only reviewers for:

1. npm provenance, lifecycle scripts, and dependency risk;
2. Pi compatibility/resource conflicts, including Ponytail vs Caveman and advisor disabled state;
3. Nix scope, generated settings, and preservation of unrelated work.

Route any accepted fix to one writer, then re-run affected checks.

**Step 4: Final status**

```bash
git status --short
git log --oneline --decorate -6
git diff main...HEAD --stat
git diff main...HEAD --name-only -- flake.lock
```

Expected: clean branch with scoped plan, package update, compatibility fix, and follow-up documentation commits; no `flake.lock` change. Do not require a fixed commit count.

---

### Post-merge user activation

Activation is intentionally not performed by the implementation workflow. It requires a separate user action after merge.

1. Apply the Home Manager generation:

   ```bash
   home-manager switch --flake .#daniel
   ```

2. Restart Pi and allow npm package reconciliation to finish.
3. Run `/reload`, or restart Pi again, after reconciliation.
4. Verify runtime resources:
   - `/subagents-doctor` completes successfully;
   - `/ponytail status` reports expected Ponytail state;
   - `/advisor` reports advisor disabled;
   - Pi exposes `pi-lens-ast-grep`, `pi-lens-lsp-navigation`, `pi-lens-write-ast-grep-rule`, and `pi-lens-write-tree-sitter-rule`.
