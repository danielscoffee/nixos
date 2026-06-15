{ pkgs, ... }:
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

    settings = {
      model = "gpt-5-codex";
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
      - Use `rg`/`fd` for search. Read files before editing.
      - For bugs: reproduce or identify failing path, find root cause, fix, verify.
      - Run relevant checks before claiming done. Show commands + results.
      - Do not commit, push, force-reset, delete data, or run destructive commands unless explicitly asked.
      - If task touches secrets, credentials, auth, or prod config: pause and ask.
      - For Nix/NixOS: prefer `nix flake check`, `nix build`, `nixos-rebuild dry-run` before switch.

      @/home/daniel/.codex/RTK.md
    '';

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
