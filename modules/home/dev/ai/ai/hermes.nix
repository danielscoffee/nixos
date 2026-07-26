{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.hermes-workstation;
  system = pkgs.stdenv.hostPlatform.system;
  upstreamPackage = inputs.hermes-agent.packages.${system}.messaging;
  skillDirectory = toString ./hermes/skills;
  secretFile = "${config.xdg.configHome}/hermes/secrets.env";
  hermesConfig = {
    _config_version = 33;
    terminal = {
      backend = "local";
      cwd = ".";
      timeout = 600;
      home_mode = "auto";
      env_passthrough = [ ];
      docker_mount_cwd_to_workspace = false;
    };
    worktree = true;
    worktree_sync = false;
    max_concurrent_sessions = 1;
    group_sessions_per_user = true;
    streaming.enabled = false;
    display.platforms.discord.interim_assistant_messages = false;
    memory = {
      memory_enabled = true;
      user_profile_enabled = true;
      write_approval = true;
      memory_char_limit = 2200;
      user_char_limit = 1375;
    };
    skills = {
      external_dirs = [ skillDirectory ];
      template_vars = true;
      inline_shell = false;
      guard_agent_created = true;
      write_approval = true;
      creation_nudge_interval = 0;
    };
    agent = {
      max_turns = 90;
      verify_on_stop = true;
      disabled_toolsets = [ "delegation" ];
      coding_instructions = ''
        Act as repository orchestrator. For implementation, load pi-coder and delegate edits to existing Pi CLI. Keep one Pi worker active. Inspect and validate its work; do not edit project files while Pi owns task. Never push, merge, deploy, activate system configuration, or discard user work.
      '';
    };
    approvals = {
      mode = "manual";
      timeout = 60;
      cron_mode = "deny";
      deny = [
        "*git*push*"
        "*nixos-rebuild*switch*"
        "*home-manager*switch*"
      ];
      mcp_reload_confirm = true;
      destructive_slash_confirm = true;
    };
    security = {
      allow_private_urls = false;
      redact_secrets = true;
      tirith_enabled = true;
      tirith_path = "tirith";
      tirith_timeout = 5;
      tirith_fail_open = false;
      allow_lazy_installs = false;
    };
  }
  // lib.optionalAttrs (cfg.model != "") {
    model = {
      default = cfg.model;
      provider = cfg.provider;
      openai_runtime = if cfg.provider == "openai-codex" then "codex_app_server" else "auto";
    };
  };
in
{
  options.programs.hermes-workstation = {
    enable = lib.mkEnableOption "declarative Hermes orchestrator for existing Pi";
    package = lib.mkOption {
      type = lib.types.package;
      default = upstreamPackage;
      description = "Pinned official Hermes package.";
    };
    model = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "anthropic/claude-opus-4.6";
      description = "Optional default model; empty requires per-run model selection.";
    };
    provider = lib.mkOption {
      type = lib.types.str;
      default = "auto";
      description = "Hermes inference provider used when model is set.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    home.sessionVariables = {
      HERMES_HOME = "${config.home.homeDirectory}/.hermes";
      HERMES_MANAGED = "nixos";
      CODEX_HOME = "${config.home.homeDirectory}/.codex";
    };

    systemd.user.tmpfiles.rules = [
      "d %h/.hermes 0700 - - -"
      "d %h/.hermes/cron 0700 - - -"
      "d %h/.hermes/logs 0700 - - -"
      "d %h/.hermes/memories 0700 - - -"
      "d %h/.hermes/plugins 0700 - - -"
      "d %h/.hermes/sessions 0700 - - -"
      "d %h/.config/hermes 0700 - - -"
      "f %h/.config/hermes/secrets.env 0600 - - -"
    ];

    home.file = {
      ".hermes/config.yaml".text = builtins.toJSON hermesConfig;
      ".hermes/.managed".text = "NixOS\n";
      ".hermes/.env".source = config.lib.file.mkOutOfStoreSymlink secretFile;
    };

    xdg.dataFile = {
      "hermes-pi/project-template" = {
        source = ./hermes/project-template;
        recursive = true;
      };
      "hermes-pi/secrets.env.example".source = ./hermes/secrets.env.example;
    };
  };
}
