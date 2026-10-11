{
  config,
  lib,
  pkgs,
  ...
}:
let
  settingsPath = "${config.programs.claude-code.configDir}/settings.json";
  nixSettings = config.home.file.${settingsPath}.source;

  src = import ./skill-sources.nix { inherit pkgs; };
  # Picked from github:emilkowalski/skills; animate-expo, ask-sonner and
  # write-swift are skipped (no Expo, Sonner or Swift in use).
  pickedEmilSkills = [
    "animate"
    "animation-vocabulary"
    "apple-design"
    "break-ui"
    "emil-design-eng"
    "find-animation-opportunities"
    "improve-animations"
    "mobile-native"
    "pick-ui-library"
    "prototype"
    "review-animations"
  ];
  # Dropped from the taste and vercel collections: they need image
  # generation, Google Stitch or Codex; are superseded (taste-skill-v1,
  # gpt-tasteskill); are covered by impeccable (redesign-skill,
  # soft-skill); fight terse output (output-skill); or target React Native.
  excludedSkills = [
    "brandkit"
    "gpt-tasteskill"
    "image-to-code-skill"
    "imagegen-frontend-mobile"
    "imagegen-frontend-web"
    "output-skill"
    "react-native-skills"
    "redesign-skill"
    "soft-skill"
    "stitch-skill"
    "taste-skill-v1"
  ];
  # Reachable as /<name> but never auto-loaded: triggers that overlap
  # impeccable, style presets, deliberate audits, and the biggest
  # descriptions.
  # The GSAP and three.js packs join this list in the build script.
  invokeOnlySkills = [
    "animation-vocabulary"
    "brutalist-skill"
    "bunshin"
    "cast"
    "design-dna"
    "find-animation-opportunities"
    "improve-animations"
    "minimalist-skill"
    "motion-design"
    "paint"
    "taste-skill"
    "transitions-dev"
    "ui-ux-pro-max"
  ];
  # Claude Code only discovers skills/<name>/SKILL.md, so flatten the
  # nested upstream collections Pi loads as skills/{taste,vercel}/<name>.
  skills = pkgs.runCommandLocal "claude-code-shared-skills" { } ''
    mkdir -p $out
    ln -s ${src.playwrightCliSource}/skills/playwright-cli $out/playwright-cli
    ln -s ${src.graphifySkills}/claude $out/graphify
    ln -s ${./claude/skills/model-routing} $out/model-routing
    ln -s ${src.securityAuditSkill}/skills/security-audit $out/security-audit
    ln -s ${src.seoSource}/skills/seo $out/seo
    ln -s ${src.stopSlopSkill} $out/stop-slop
    ln -s ${src.humanizerSkill} $out/humanizer
    ln -s ${src.impeccableSkill} $out/impeccable
    ln -s ${src.transitionsDevSource}/skills/transitions-dev $out/transitions-dev
    ln -s ${src.uiUxProMaxSkill} $out/ui-ux-pro-max
    ln -s ${./claude/skills/high-end-frontend} $out/high-end-frontend
    for d in ${src.tasteSkills}/skills/*/ ${src.vercelAgentSkills}/skills/*/; do
      ln -s "$d" "$out/$(basename "$d")"
    done
    for d in ${src.ponytailSkills}/*/; do
      ln -s "$d" "$out/$(basename "$d")"
    done
    for s in ${lib.escapeShellArgs src.localSkills}; do
      ln -s ${./pi/skills}/"$s" "$out/$s"
    done
    for s in ${lib.escapeShellArgs pickedEmilSkills}; do
      ln -s ${src.emilSkills}/skills/"$s" "$out/$s"
    done
    for s in ${lib.escapeShellArgs excludedSkills}; do
      rm "$out/$s" || { echo "excluded skill $s not found upstream" >&2; exit 1; }
    done

    # UI/motion packs, reached through high-end-frontend. Genjutsu's
    # entry skills find _jutsu/ as their sibling.
    invoke_only=(${lib.escapeShellArgs invokeOnlySkills})
    for d in ${src.gsapSkills}/skills/*/ ${src.threejsSkills}/skills/*/; do
      s=$(basename "$d")
      # Teaches removed WebGPU post-processing APIs and pre-OutputPass
      # color handling.
      [ "$s" = threejs-postprocessing ] && continue
      ln -s "$d" "$out/$s"
      invoke_only+=("$s")
    done
    ln -s ${src.motionDesignSource}/skills/motion-design $out/motion-design
    ln -s ${src.designDnaSkill} $out/design-dna
    for s in bunshin cast paint _jutsu; do
      ln -s ${src.genjutsuSource}/skills/$s $out/$s
    done

    for s in "''${invoke_only[@]}"; do
      skill=$(readlink -f "$out/$s")
      rm "$out/$s"
      cp -r "$skill" "$out/$s"
      chmod -R u+w "$out/$s"
      if [ "$(head -1 "$out/$s/SKILL.md")" != "---" ]; then
        echo "$s: SKILL.md has no frontmatter to patch" >&2
        exit 1
      fi
      sed -i '1a disable-model-invocation: true' "$out/$s/SKILL.md"
    done
    # Genjutsu pre-approves Bash/Edit/Write (bunshin adds Agent and
    # Workflow) for its whole run; drop that so its runs prompt as usual.
    for s in bunshin cast paint; do
      sed -i '/^allowed-tools:/d' "$out/$s/SKILL.md"
    done
  '';
  # Codex delegation/review plugin (v1.0.6). State lives in
  # CLAUDE_PLUGIN_DATA or $TMPDIR, so a read-only store copy works.
  codexPluginCc = pkgs.fetchFromGitHub {
    owner = "openai";
    repo = "codex-plugin-cc";
    rev = "db52e28f4d9ded852ab3942cea316258ae4ef346";
    hash = "sha256-S/R4kHTcIHBcG0TRX063C7ILXZZm0oMqunchPGg6ToU=";
  };
in
{
  # Claude Code writes to settings.json at runtime (/model, /effort, ...),
  # so keep it a mutable file: Nix-declared keys win, runtime keys persist.
  home.file.${settingsPath}.enable = false;

  home.activation.claudeCodeSettings = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    target=${lib.escapeShellArg settingsPath}
    run mkdir -p "$(dirname "$target")"
    if [ -L "$target" ]; then
      run rm "$target"
    fi
    if [ -f "$target" ] && ${pkgs.jq}/bin/jq -e . "$target" >/dev/null 2>&1; then
      tmp="$(mktemp)"
      ${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$target" ${nixSettings} > "$tmp"
      run install -m644 "$tmp" "$target"
      rm -f "$tmp"
    else
      run install -m644 ${nixSettings} "$target"
    fi
  '';

  # Saved Workflow scripts: each runs as /<name> in every project.
  home.file."${config.programs.claude-code.configDir}/workflows/routed-task.js".source =
    ./claude/workflows/routed-task.js;

  home.file.".claude/RTK.md" = {
    force = true;
    text = ''
      # RTK - Rust Token Killer

      **Usage**: Token-optimized CLI proxy (60-90% savings on dev operations)

      ## Meta Commands (always use rtk directly)

      ```bash
      rtk gain              # Show token savings analytics
      rtk gain --history    # Show command usage history with savings
      rtk discover          # Analyze Claude Code history for missed opportunities
      rtk proxy <cmd>       # Execute raw command without filtering (for debugging)
      ```

      ## Installation Verification

      ```bash
      rtk --version         # Should show: rtk X.Y.Z
      rtk gain              # Should work (not "command not found")
      which rtk             # Verify correct binary
      ```

      ⚠️ **Name collision**: If `rtk gain` fails, you may have reachingforthejack/rtk (Rust Type Kit) installed instead.

      ## Hook-Based Usage

      All other commands are automatically rewritten by the Claude Code hook.
      Example: `git status` → `rtk git status` (transparent, 0 tokens overhead)

      Refer to CLAUDE.md for full command reference.
    '';
  };

  programs.claude-code = {
    enable = true;
    inherit skills;
    plugins.codex = "${codexPluginCc}/plugins/codex";

    settings = {
      model = "claude-opus-5-5";
      permissionMode = "acceptEdits";
      includeCoAuthoredBy = false;
      cleanupPeriodDays = 30;

      env = {
        CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1";
      };

      permissions = {
        defaultMode = "acceptEdits";
        disableBypassPermissionsMode = "disable";
        deny = [
          "Bash(rm -rf /:*)"
          "Bash(rm -rf ~:*)"
          "Bash(sudo rm:*)"
          "Bash(git push --force:*)"
          "Bash(git reset --hard:*)"
          "Bash(git clean -fd:*)"
          "Read(~/.ssh/**)"
          "Read(~/.gnupg/**)"
          "Read(**/.env*)"
          "Read(**/secrets/**)"
        ];
      };

      hooks = {
        PreToolUse = [
          {
            matcher = "Bash";
            hooks = [
              {
                type = "command";
                command = "rtk hook claude";
              }
            ];
          }
        ];
      };
    };

    context = ''
      # User preferences

      - Be terse, direct, technical. Skip fluff.
      - Before code changes: inspect context, state plan briefly, then edit.
      - Prefer minimal, focused diffs. Do not rewrite unrelated code.
      - Use `rg`/`fd` for search. Read files before editing.
      - For bugs: reproduce or identify failing path, find root cause, fix, verify.
      - Run relevant checks before claiming done. Show commands + results.
      - Do not commit, push, force-reset, delete data, or run destructive commands unless explicitly asked.
      - If task touches secrets, credentials, auth, or prod config: pause and ask.
      - For Nix/NixOS: prefer `nix flake check`, `nix build`, `nixos-rebuild dry-run` before switch.

      @RTK.md
    '';

    commands = {
      plan = ''
        ---
        description: Build concise implementation plan without editing files
        argument-hint: [task]
        allowed-tools: Read, Grep, Glob, Bash(git status:*), Bash(git diff:*), Bash(find:*), Bash(rg:*)
        ---

        Inspect repository and create concise implementation plan for: $ARGUMENTS

        Rules:
        - Do not edit files.
        - Identify relevant files, risks, verification commands.
        - End with numbered steps and first command to run.
      '';

      fix = ''
        ---
        description: Fix bug with root-cause workflow
        argument-hint: [bug or failure]
        ---

        Fix: $ARGUMENTS

        Workflow:
        1. Reproduce or locate failing behavior.
        2. Identify root cause, not symptom.
        3. Make smallest safe change.
        4. Add/update test when practical.
        5. Run relevant verification.
        6. Report changed files and command output summary.
      '';

      review = ''
        ---
        description: Review current diff for bugs, safety, tests, maintainability
        allowed-tools: Read, Grep, Glob, Bash(git diff:*), Bash(git status:*), Bash(git log:*)
        ---

        Review current changes for correctness, safety, tests, and maintainability.

        Focus:
        - Bugs/regressions
        - Missing tests or verification
        - Security/secrets/destructive operations
        - Overbroad diffs

        Use `git diff --stat` and `git diff`. Return findings by severity, with file/line when possible.
      '';

      "commit-msg" = ''
        ---
        description: Propose commit messages without committing
        allowed-tools: Bash(git diff:*), Bash(git status:*), Bash(git log:*)
        ---

        Inspect staged and unstaged changes. Propose 3 commit messages.

        Do not commit unless explicitly asked.
        Prefer conventional style when obvious.
      '';
    };

    outputStyles = {
      concise = ''
        # Concise

        Answer terse, direct, technical.
        Use bullets for findings.
        Include file paths and commands when relevant.
        Avoid praise, filler, and long explanations unless asked.
      '';
    };

    lspServers = {
      nix = {
        command = "nil";
        args = [ ];
        extensionToLanguage = {
          ".nix" = "nix";
        };
      };

      typescript = {
        command = "typescript-language-server";
        args = [ "--stdio" ];
        extensionToLanguage = {
          ".ts" = "typescript";
          ".tsx" = "typescriptreact";
          ".js" = "javascript";
          ".jsx" = "javascriptreact";
        };
      };

      python = {
        command = "basedpyright-langserver";
        args = [ "--stdio" ];
        extensionToLanguage = {
          ".py" = "python";
        };
      };

      go = {
        command = "gopls";
        args = [ ];
        extensionToLanguage = {
          ".go" = "go";
        };
      };

      java = {
        command = "jdtls";
        args = [ ];
        extensionToLanguage = {
          ".java" = "java";
        };
      };
    };
  };

  home.packages = with pkgs; [
    nil
    nixfmt
    basedpyright
    gopls
    jdt-language-server
    typescript
    typescript-language-server
    nodejs
    git
    ripgrep
    fd
    jq
  ];
}
