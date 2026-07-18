# Pi Plugin Update Implementation Plan

> **REQUIRED SUB-SKILL:** Use the executing-plans skill to implement this plan task-by-task.

**Goal:** Update exact Nix-managed Pi package pins and add official Ponytail plus advisor without enabling advisor or changing model defaults.

**Architecture:** Modify only `programs.pi-coding-agent.settings.packages` in `pi.nix`. Resolve and inspect exact npm packages in an isolated temporary agent directory, then validate the generated Home Manager settings and Pi resource discovery.

**Tech Stack:** Nix/Home Manager, Pi 0.80.x package loader, npm registry, Node/Bun.

**Design:** `docs/plans/2026-07-18-pi-plugin-update-design.md`

**Git authorization:** Commit steps require explicit user authorization. User selected same-session planned execution; this authorizes listed scoped local commits only. Never push.

---

### Task 1: Update exact package pins

**Files:**
- Modify: `modules/home/dev/ai/ai/pi.nix`

**Step 1: Verify RED expectations**

Run assertions proving current package list does not yet match target:

```bash
! grep -q 'npm:pi-web-access@0.13.0' modules/home/dev/ai/ai/pi.nix
! grep -q 'npm:@dietrichgebert/ponytail@4.8.4' modules/home/dev/ai/ai/pi.nix
! grep -q 'npm:pi-advisor@0.3.0' modules/home/dev/ai/ai/pi.nix
```

Expected: all exit 0 because target strings are absent.

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
```

Do not change default provider/model, resource links, extension source, `extraPackages`, or `flake.lock`.

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
nixfmt modules/home/dev/ai/ai/pi.nix
git diff --check
```

Expected: all exit 0.

**Step 4: Commit**

```bash
git add modules/home/dev/ai/ai/pi.nix
git commit -m "chore(pi): update plugins"
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

Create a temporary npm project and run `npm install --ignore-scripts --save-exact` with all nine package specs. Set temporary `HOME`, `XDG_CONFIG_HOME`, `PI_CODING_AGENT_DIR`, and npm cache where practical. Never write active `~/.pi/agent`.

Expected: install exits 0, exact direct dependencies appear in lockfile, no package lifecycle scripts execute.

**Step 3: Audit package tree**

```bash
npm audit --omit=dev --audit-level=high
npm ls --depth=0
```

Expected: no high/critical production vulnerabilities and every direct package resolved at exact target version.

**Step 4: Validate Pi manifests/resources**

Use Pi's `DefaultResourceLoader` against temporary agent settings and isolated `npm/node_modules`. Verify:

- all configured package sources resolve;
- zero package-resource diagnostics;
- harness custom agents/skills remain separate and discoverable in source validation;
- Ponytail contributes extension plus Ponytail skills;
- advisor contributes extension only;
- pi-subagents contributes bundled agents/prompts/skill;
- advisor is not enabled and no `advisor.json` is created;
- no model call occurs.

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
git log --oneline --decorate -5
git diff HEAD^ --stat
git diff HEAD^ -- modules/home/dev/ai/ai/pi.nix
```

Expected: clean branch and one scoped package-list implementation commit after plan commit; no `flake.lock` change.
