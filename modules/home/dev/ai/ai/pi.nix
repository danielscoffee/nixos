{ lib, pkgs, ... }:
let
  tasteSkills = pkgs.fetchFromGitHub {
    owner = "Leonxlnx";
    repo = "taste-skill";
    rev = "72e299530e2eb31ed8da06181bc19f6c18a00821";
    hash = "sha256-DH1Q+1FgcVHnxMuXwifutCtTXulJjDgzwmQ9kSbL0a8=";
  };
  vercelAgentSkills = pkgs.fetchFromGitHub {
    owner = "vercel-labs";
    repo = "agent-skills";
    rev = "dd089a8c752c966dee8bf0f27cb625ba193ffd9e";
    hash = "sha256-fXbWS0+jtRYXdVn1KdqBdU0wEirrg5t/3IxdqPaAs8M=";
  };
  awesomeDesignMd = pkgs.fetchFromGitHub {
    owner = "VoltAgent";
    repo = "awesome-design-md";
    rev = "8147538b4226ae41e2487a9179e3bcc1f68e8554";
    hash = "sha256-AaLS2goYWZm8WHd+c5JWQxJlHZsF/2HKjs+0epK6R1Y=";
  };
  playwrightCliSource = pkgs.fetchFromGitHub {
    owner = "microsoft";
    repo = "playwright-cli";
    rev = "2f85a94b7b885dbf4a5d34462f253a8746a690c9";
    hash = "sha256-KH2rl0uS/zFPebjmg6MZndcl6Llx4c9/yfCGvisBn7g=";
  };
  playwrightCli = pkgs.buildNpmPackage (finalAttrs: {
    pname = "playwright-cli";
    version = "0.1.18";

    src = playwrightCliSource;
    npmDepsHash = "sha256-3kqiQvGtZfsmLHVWeCSM1yOYb+ws2x1vMPC1OuvrKAI=";
    npmRebuildFlags = [ "--ignore-scripts" ];
    dontNpmBuild = true;

    nativeBuildInputs = [ pkgs.makeWrapper ];
    postInstall = ''
      wrapProgram "$out/bin/playwright-cli" --set NO_UPDATE_NOTIFIER 1
    '';

    doInstallCheck = true;
    nativeInstallCheckInputs = [ pkgs.versionCheckHook ];
    versionCheckProgram = "${placeholder "out"}/bin/playwright-cli";

    meta = {
      description = "Token-efficient Playwright CLI for coding agents";
      homepage = "https://github.com/microsoft/playwright-cli";
      license = lib.licenses.asl20;
      mainProgram = "playwright-cli";
    };
  });
in
{
  home.packages = [ playwrightCli ];

  home.file.".pi/agent/skills/taste" = {
    force = true;
    recursive = true;
    source = "${tasteSkills}/skills";
  };
  home.file.".pi/agent/skills/vercel" = {
    force = true;
    recursive = true;
    source = "${vercelAgentSkills}/skills";
  };
  home.file.".pi/agent/skills/playwright-cli" = {
    force = true;
    recursive = true;
    source = "${playwrightCliSource}/skills/playwright-cli";
  };
  home.file.".pi/agent/skills/frontend-design/SKILL.md" = {
    force = true;
    source = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/anthropics/claude-code/45bdfa96ca415da92e62b6ca85a1d6e29adf3c44/plugins/frontend-design/skills/frontend-design/SKILL.md";
      hash = "sha256-Fgjqd/u2/DDROpfRLPqOvzE1jUDw3Ze+7SSCnWs/Rd0=";
    };
  };
  home.file.".pi/agent/skills/frontend-design/LICENSE.txt" = {
    force = true;
    source = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/anthropics/claude-code/45bdfa96ca415da92e62b6ca85a1d6e29adf3c44/LICENSE.md";
      hash = "sha256-coFY/RA3FD+taQfo+jSAQXflmLcyZRlQP+g8r974SeY=";
    };
  };
  home.file.".local/share/awesome-design-md" = {
    force = true;
    recursive = true;
    source = "${awesomeDesignMd}/design-md";
  };
  home.file.".playwright/cli.config.json" = {
    force = true;
    text = builtins.toJSON {
      browser = {
        browserName = "chromium";
        launchOptions.executablePath = lib.getExe pkgs.chromium;
      };
    };
  };

  home.file.".pi/agent/extensions/rtk.ts" = {
    force = true;
    text = ''
      // RTK Pi extension — rewrites bash commands to use rtk for token savings.
      // Requires: rtk >= 0.23.0 in PATH.
      //
      // This is a thin delegating extension: all rewrite logic lives in `rtk rewrite`,
      // which is the single source of truth (src/discover/registry.rs).
      // To add or change rewrite rules, edit the Rust registry — not this file.
      //
      // Exit code contract for `rtk rewrite`:
      //   0 + stdout  Rewrite found → mutate command
      //   1           No RTK equivalent → pass through unchanged
      //   3 + stdout  Rewrite (advisory) → mutate command

      import type { ExtensionAPI } from "@earendil-works/pi-coding-agent"
      import { isToolCallEventType } from "@earendil-works/pi-coding-agent"

      const REWRITE_TIMEOUT_MS = 2_000
      const MIN_SUPPORTED_RTK_MINOR = 23

      // Parse "X.Y.Z" semver, return [major, minor, patch] or null.
      function parseSemver(raw: string): [number, number, number] | null {
        const m = raw.trim().match(/(\d+)\.(\d+)\.(\d+)/)
        if (!m) return null
        return [parseInt(m[1], 10), parseInt(m[2], 10), parseInt(m[3], 10)]
      }

      // Calls `rtk rewrite`; returns the rewritten command or null (pass through).
      async function rewriteCommand(
        pi: ExtensionAPI,
        cmd: string,
        signal?: AbortSignal
      ): Promise<string | null> {
        const result = await pi.exec("rtk", ["rewrite", cmd], {
          timeout: REWRITE_TIMEOUT_MS,
          signal,
        })
        if (result.killed) return null
        if (result.code !== 0 && result.code !== 3) return null
        return result.stdout.trim() || null
      }

      export default async function (pi: ExtensionAPI) {
        // Probe rtk version at load time; disables extension if missing or too old.
        const ver = await pi.exec("rtk", ["--version"], { timeout: REWRITE_TIMEOUT_MS })
        if (ver.code !== 0) {
          console.warn("[rtk] rtk binary not found in PATH — extension disabled")
          return
        }

        // Warn and bail if rtk predates 0.23.0 (when `rtk rewrite` was introduced).
        const parsed = parseSemver(ver.stdout.replace(/^rtk\s+/, ""))
        if (parsed) {
          const [major, minor] = parsed
          if (major === 0 && minor < MIN_SUPPORTED_RTK_MINOR) {
            console.warn(`[rtk] rtk ''${ver.stdout.trim()} is too old (need >= 0.23.0) — extension disabled`)
            return
          }
        }

        pi.on("tool_call", async (event, ctx) => {
          try {
            if (!isToolCallEventType("bash", event)) return

            const cmd = event.input.command
            if (typeof cmd !== "string" || cmd.trim() === "") return

            if (cmd.startsWith("rtk ")) return
            if (process.env.RTK_DISABLED === "1") return

            // Delegate to RTK.
            const rewritten = await rewriteCommand(pi, cmd, ctx.signal)
            if (rewritten && rewritten !== cmd) {
              event.input.command = rewritten
            }
          } catch (err) {
            // Fail open: never block execution on an unexpected error.
            console.warn("[rtk] unexpected error in tool_call handler; passing through command", err)
            return
          }
        })
      }
    '';
  };

  home.file.".pi/agent/AGENTS.md" = {
    force = true;
    source = ./pi/AGENTS.md;
  };
  home.file.".pi/agent/agents/architect.md" = {
    force = true;
    source = ./pi/agents/architect.md;
  };
  home.file.".pi/agent/agents/asker.md" = {
    force = true;
    source = ./pi/agents/asker.md;
  };
  home.file.".pi/agent/agents/developer.md" = {
    force = true;
    source = ./pi/agents/developer.md;
  };
  home.file.".pi/agent/agents/devops-infra.md" = {
    force = true;
    source = ./pi/agents/devops-infra.md;
  };
  home.file.".pi/agent/agents/nixos-diagnostician.md" = {
    force = true;
    source = ./pi/agents/nixos-diagnostician.md;
  };
  home.file.".pi/agent/agents/qa.md" = {
    force = true;
    source = ./pi/agents/qa.md;
  };
  home.file.".pi/agent/agents/searcher.md" = {
    force = true;
    source = ./pi/agents/searcher.md;
  };
  home.file.".pi/agent/agents/security-auditor.md" = {
    force = true;
    source = ./pi/agents/security-auditor.md;
  };
  home.file.".pi/agent/prompts/autonomous.md" = {
    force = true;
    source = ./pi/prompts/autonomous.md;
  };
  home.file.".pi/agent/prompts/grill.md" = {
    force = true;
    source = ./pi/prompts/grill.md;
  };
  home.file.".pi/agent/prompts/repo-health.md" = {
    force = true;
    source = ./pi/prompts/repo-health.md;
  };
  home.file.".pi/agent/prompts/security-audit.md" = {
    force = true;
    source = ./pi/prompts/security-audit.md;
  };
  home.file.".pi/agent/skills/autonomous-atomic/SKILL.md" = {
    force = true;
    source = ./pi/skills/autonomous-atomic/SKILL.md;
  };
  home.file.".pi/agent/skills/grill-me/SKILL.md" = {
    force = true;
    source = ./pi/skills/grill-me/SKILL.md;
  };
  home.file.".pi/agent/skills/grill-me/LICENSE" = {
    force = true;
    source = ./pi/skills/grill-me/LICENSE;
  };
  home.file.".pi/agent/skills/code-review" = {
    force = true;
    recursive = true;
    source = ./pi/skills/code-review;
  };
  home.file.".pi/agent/skills/domain-modeling" = {
    force = true;
    recursive = true;
    source = ./pi/skills/domain-modeling;
  };
  home.file.".pi/agent/skills/nix-managed-debugging/SKILL.md" = {
    force = true;
    source = ./pi/skills/nix-managed-debugging/SKILL.md;
  };
  home.file.".pi/agent/skills/teach" = {
    force = true;
    recursive = true;
    source = ./pi/skills/teach;
  };
  home.file.".pi/agent/skills/wizard" = {
    force = true;
    recursive = true;
    source = ./pi/skills/wizard;
  };
  home.file.".pi/agent/skills/writing-for-agents" = {
    force = true;
    recursive = true;
    source = ./pi/skills/writing-for-agents;
  };

  programs.pi-coding-agent = {
    enable = true;

    extraPackages = with pkgs; [
      nil
      basedpyright
      gopls
      jdt-language-server
      typescript
      nodejs
      bun
      playwrightCli
      rtk
      git
      ripgrep
      fd
      jq
    ];

    settings = {
      defaultProjectTrust = "ask";
      defaultProvider = "openai-codex";
      defaultModel = "gpt-6-astra";
      defaultThinkingLevel = "max";

      packages = [
        "npm:pi-agent-sandbox@0.2.0"
        "npm:pi-caveman@1.0.8"
        "npm:pi-superpowers@0.2.0"
        "npm:pi-web-access@0.19.0"
        "npm:pi-subagents@0.45.0"
        "npm:pi-lens@3.8.74"
        "npm:pi-powerline-footer@0.12.2"
        "npm:@ayulab/pi-rewind@0.4.6"
        "npm:@dietrichgebert/ponytail@4.9.0"
        "npm:pi-advisor@0.3.0"
      ];

      skills = [ "npm/node_modules/pi-lens/skills" ];
    };
  };
}
