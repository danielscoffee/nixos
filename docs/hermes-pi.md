# Declarative Hermes + Pi workstation

## Architecture

- Home Manager installs official pinned Hermes `messaging` package, including
  Discord runtime dependencies.
- Existing Pi installation remains unchanged and authoritative for Pi auth,
  models, sessions, extensions, packages, prompts, skills, and global policy.
- Hermes orchestrates repository work through read-only `pi-coder` skill.
- Hermes native `worktree: true` creates isolated branch and checkout.
  `worktree_sync: false` bases work on exact local `HEAD` without network fetch.
- Skill invokes existing `pi --print` in current Hermes worktree. No custom
  bridge, daemon, listener, RPC parser, or repository hook exists.
- Hermes subagent toolset is disabled and concurrent sessions are capped at one.
- No gateway user service is declared; gateway runs only when started manually.

This design intentionally favors declarative native features over custom code.
Hermes cannot enforce or inspect Pi's internal commands through its approval
layer. Isolation relies on native Git worktree, existing Pi policy, bounded task
brief, and post-run Git validation.

## Managed files and mutable state

Home Manager owns:

- `~/.hermes/config.yaml` — non-secret immutable config symlink.
- `~/.hermes/.managed` — disables Hermes self-update/config mutation paths.
- `~/.hermes/.env` — out-of-store symlink to secret file.
- `~/.local/share/hermes-pi/project-template/` — optional project policy
  template.

Mutable state stays outside `/nix/store` under `~/.hermes`: sessions, memories,
logs, caches, pending approvals, and local skills. Disabling module leaves
mutable state intact.

Systemd user tmpfiles declaratively creates and enforces:

- `~/.hermes` and required `cron`, `logs`, `memories`, `plugins`, and
  `sessions` subdirectories, mode `0700`.
- `~/.config/hermes` mode `0700`.
- `~/.config/hermes/secrets.env` mode `0600`.

## Secrets

Never put values in Nix source, flake inputs, generated config, task briefs, or
project files. Edit only runtime file:

```sh
$EDITOR ~/.config/hermes/secrets.env
chmod 600 ~/.config/hermes/secrets.env
```

Use only variables required by selected provider or messaging platform. Template:

```sh
cat ~/.local/share/hermes-pi/secrets.env.example
```

Provider config is declarative in `modules/home/dev/ai/ai.nix`:

```nix
programs.hermes-workstation = {
  enable = true;
  provider = "openai-codex";
  model = "gpt-5.6-sol";
};
```

Managed mode does not persist interactive setup changes. Set provider/model in
Nix before routine use. No paid model call is part of build or validation.

### OpenAI Codex login

Hermes uses `openai-codex` with Codex app-server runtime. Codex CLI handles
model requests and tool execution, so it uses standard Codex CLI login state:

```sh
codex login
```

Hermes passes `CODEX_HOME=~/.codex` to Codex. `codex login` writes
`~/.codex/auth.json`; Hermes does not copy or modify it. Pi's
`~/.pi/agent/auth.json` is a separate format and must not be copied or
symlinked. OAuth refresh tokens are single-use; sharing token files can log
Pi or Codex out.

No `hermes auth add` is needed for current app-server configuration. If you
switch back to Hermes' direct Codex Responses runtime, use
`hermes auth add openai-codex` separately.

### Discord gateway

Put runtime values only in `~/.config/hermes/secrets.env`:

```dotenv
DISCORD_BOT_TOKEN=your-bot-token
DISCORD_ALLOWED_USERS=your-discord-user-id
# Optional target for proactive messages and cron delivery:
DISCORD_HOME_CHANNEL=your-channel-id
```

`DISCORD_ALLOWED_USERS` accepts comma-separated user IDs. Without an explicit
user, role, channel, or allow-all rule, Hermes denies all users. Keep this
allowlist instead of enabling allow-all. Start foreground gateway manually:

```sh
hermes gateway
```

Stop with Ctrl+C. No systemd gateway service is installed or enabled.

## Security baseline

- Local terminal backend, real user home, 10-minute command timeout.
- No environment passthrough into tool sandboxes unless loaded skill explicitly
  declares it.
- Manual dangerous-command approvals.
- Unconditional deny patterns for Git push and NixOS/Home Manager activation.
- Tirith enabled fail-closed.
- Runtime package installation disabled.
- Private-network URL access disabled and secret redaction enabled.
- Memory and agent-created skill writes require approval.
- External `pi-coder` skill is read-only from Nix store.
- Hermes delegation toolset disabled; one active Hermes session maximum.

Pi subprocess uses existing Pi security policy. Hermes cannot mediate commands
Pi launches internally; review Pi policy before delegation.

## Optional project template

Inspect installed template, then merge selected files without overwriting
existing policy:

```sh
find ~/.local/share/hermes-pi/project-template -maxdepth 3 -type f -print
```

Template contains `AGENTS.md`, `.hermes.md`, `.pi/settings.json`, task brief
example, and Git ignore snippet. Nothing is injected into existing repositories.

## Run

Start only from clean Git repository:

```sh
cd /path/to/repository
hermes
```

Ask Hermes to load `pi-coder` and delegate one bounded implementation task.
Hermes automatically enters isolated worktree. Skill requires:

1. clean primary checkout check;
2. bounded `.hermes-pi-task.md`;
3. one `pi --print` worker;
4. actual commit/diff review;
5. independent focused and repository validation;
6. Pi-owned correction loop;
7. clean delegated branch before normal exit.

Clean worktrees are removed by Hermes on exit; dirty failed worktrees remain for
recovery. Branches are never merged or pushed automatically.

## Validation without activation

Run from repository root:

```sh
nix flake metadata
nix eval .#homeConfigurations.daniel.config.programs.hermes-workstation.enable
nix build .#homeConfigurations.daniel.activationPackage --no-link
nix build .#nixosConfigurations.default.config.system.build.toplevel --no-link
nix flake check --no-build
```

Inspect package/config closure without exposing secrets:

```sh
nix eval --raw \
  .#homeConfigurations.daniel.config.programs.hermes-workstation.package.outPath
nix eval --json \
  .#homeConfigurations.daniel.config.systemd.user.tmpfiles.rules
```

Do not run `home-manager switch`, `nixos-rebuild switch`, gateway startup,
provider login, or model calls during validation.

## Upgrade and rollback

Upgrade only official pin, review lock diff, then rebuild without activation:

```sh
nix flake update hermes-agent
nix build .#homeConfigurations.daniel.activationPackage --no-link
```

Rollback declaratively: disable `programs.hermes-workstation.enable` or remove
`./ai/hermes.nix` import, then perform normal reviewed activation later.
Existing Pi and mutable `~/.hermes` state remain untouched.
