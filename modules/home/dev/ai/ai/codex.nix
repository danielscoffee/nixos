{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  src = import ./skill-sources.nix { inherit pkgs; };
  sandbox = import ./sandbox.nix { inherit lib pkgs; };
  # The engineering half of Claude Code's skills: shared local skills,
  # Graphify, Ponytail and security-audit (no frontend/design picks),
  # plus onetake.
  skills = pkgs.runCommandLocal "codex-shared-skills" { } ''
    mkdir -p $out
    ln -s ${src.graphifySkills}/codex $out/graphify
    ln -s ${src.securityAuditSkill}/skills/security-audit $out/security-audit
    ln -s ${src.onetakeSkill} $out/onetake
    for d in ${src.ponytailSkills}/*/; do
      ln -s "$d" "$out/$(basename "$d")"
    done
    for s in ${lib.escapeShellArgs src.localSkills}; do
      ln -s ${./pi/skills}/"$s" "$out/$s"
    done
  '';
in
{
  home.file.".codex/RTK.md" = {
    force = true;
    text = ''
      # RTK - Rust Token Killer (Codex CLI)

      **Usage**: Token-optimized CLI proxy for shell commands.

      ## Rule

      Always prefix shell commands with `rtk`.

      Examples:

      ```bash
      rtk git status
      rtk cargo test
      rtk npm run build
      rtk pytest -q
      ```

      ## Meta Commands

      ```bash
      rtk gain            # Token savings analytics
      rtk gain --history  # Recent command savings history
      rtk proxy <cmd>     # Run raw command without filtering
      ```

      ## Verification

      ```bash
      rtk --version
      rtk gain
      which rtk
      ```
    '';
  };

  programs.codex = {
    enable = true;
    # Runs inside the bubblewrap sandbox, with Codex's own workspace-write
    # sandbox nested in it.
    package = sandbox.wrap {
      package = inputs.codex.packages.${pkgs.stdenv.hostPlatform.system}.codex;
      rw = [
        ".codex"
        ".local/share/rtk"
      ];
    };
    mutableSettings = true;

    settings = {
      # Nix owns the binary: no self-update checks, and no auto-started
      # daemon that copies itself into ~/.codex/packages and self-updates
      # (nixpkgs patches the same default off; openai/codex#48195).
      check_for_update_on_startup = false;
      features.daemon_auto_start = false;

      model = "gpt-6-astra";
      approval_policy = "on-request";
      sandbox_mode = "workspace-write";
      model_reasoning_effort = "medium";

      shell_environment_policy = {
        "inherit" = "core";
        ignore_default_excludes = false;
      };
    };

    context = ''
      # User preferences

      - Be terse, direct, technical. Skip fluff.
      - Before code changes: inspect context, state plan briefly, then edit.
      - Prefer minimal, focused diffs. Do not rewrite unrelated code.
      - Do not write or add tests unless explicitly asked. Running existing tests/checks is fine.
      - Use `rg`/`fd` for search. Read files before editing.
      - For bugs: reproduce or identify failing path, find root cause, fix, verify.
      - Run relevant checks before claiming done. Show commands + results.
      - Do not commit, push, force-reset, delete data, or run destructive commands unless explicitly asked.
      - If task touches secrets, credentials, auth, or prod config: pause and ask.
      - For Nix/NixOS: prefer `nix flake check`, `nix build`, `nixos-rebuild dry-run` before switch.
      - Sessions run inside a bubblewrap sandbox (`ai-sandbox`): only the project (git top-level), `/tmp` and `~/.codex` are writable, and `$HOME` is a private scratch home without SSH, GPG, gh or npm credentials. Failed writes or missing credentials elsewhere are by design: report them instead of working around them.

      @/home/daniel/.codex/RTK.md
    '';

    inherit skills;

    rules = {
      default = ''
        prefix_rule(pattern = ["git", "status"], decision = "allow")
        prefix_rule(pattern = ["git", "diff"], decision = "allow")
        prefix_rule(pattern = ["git", "log"], decision = "allow")
        prefix_rule(pattern = ["rtk", "git", "status"], decision = "allow")
        prefix_rule(pattern = ["rtk", "git", "diff"], decision = "allow")
        prefix_rule(pattern = ["rtk", "git", "log"], decision = "allow")
        prefix_rule(pattern = ["rg"], decision = "allow")
        prefix_rule(pattern = ["fd"], decision = "allow")
        prefix_rule(pattern = ["find"], decision = "allow")
        prefix_rule(pattern = ["ls"], decision = "allow")
        prefix_rule(pattern = ["rtk", "grep"], decision = "allow")
        prefix_rule(pattern = ["rtk", "find"], decision = "allow")
        prefix_rule(pattern = ["rtk", "ls"], decision = "allow")
        prefix_rule(pattern = ["rtk", "read"], decision = "allow")
        prefix_rule(pattern = ["rtk", "gain"], decision = "allow")
        prefix_rule(pattern = ["nix", "eval"], decision = "allow")
        prefix_rule(pattern = ["nix", "build"], decision = "allow")
        prefix_rule(pattern = ["nix", "flake", "check"], decision = "allow")
        prefix_rule(pattern = ["rtk", "nix", "eval"], decision = "allow")
        prefix_rule(pattern = ["rtk", "nix", "build"], decision = "allow")
        prefix_rule(pattern = ["rtk", "nix", "flake", "check"], decision = "allow")
      '';
    };
  };

  home.packages = with pkgs; [
    git
    ripgrep
    fd
    jq
  ];
}
