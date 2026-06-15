{ pkgs, ... }:
{
  programs.claude-code = {
    enable = true;

    settings = {
      model = "sonnet";
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
