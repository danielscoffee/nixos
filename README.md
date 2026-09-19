# NixOS configuration

Personal flake for the `default`/`loqe` workstations, a minimal `server`, a
NixOS-WSL host, and the `daniel` standalone Home Manager profile.

## Prerequisites

- Nix with flakes enabled
- `make`
- `sudo` for activation and hardware generation

## Validate changes

```sh
make check       # evaluate every flake output and verify formatting
make fmt         # format all Nix files
make build       # build loqe (the default HOST) without activating it
make build-wsl   # build the WSL system without activating it
```

Run `make check` before rebuilding. CI runs the same evaluation and formatting
checks for pushes and pull requests.

## Apply the configuration

```sh
make rebuild              # activates .#loqe
make rebuild HOST=wsl     # activates another NixOS configuration
```

`make hardware HOST=server` generates `hosts/server/hardware-configuration.nix`
from the current machine. Always run it on the matching host and review the output
before rebuilding; hardware UUIDs are machine-specific. Without `HOST`, it targets
`loqe`. Generation failures preserve the previous file; symlink targets are refused.

`make setup` generates hardware, rebuilds the selected host, and copies the
i3/i3status/rofi dotfiles. Use it only for a matching workstation, not the server.

## Headless laptop server

`hosts/server/configuration.nix` is exported as `nixosConfigurations.server`.
It imports `modules/server/` (also exported as `nixosModules.server`): CLI essentials
(`btop`, `curl`, Git, Make, `tmux`, Vim), NetworkManager for Ethernet/Wi-Fi,
Tailscale, and OpenSSH. A terminal-only Home Manager profile adds developer tools
and dotfiles for `daniel`. No i3, games, GUI apps, desktop Home Manager, Bluetooth,
audio stack, or Docker. The local console stays available, and lid-close does not
suspend the laptop.

The host uses `x86_64-linux`, hostname `server`, and a `daniel` account with `wheel`
and `networkmanager` membership. Boot defaults to UEFI/systemd-boot, like the other
physical hosts. **Confirm the laptop uses UEFI before rebuilding**; change the
bootloader configuration first for legacy BIOS. Keep its existing
`system.stateVersion` if it differs from the repository's `24.05` default.

Provision **on the old laptop**, from this checkout:

```sh
make hardware HOST=server
```

Review the generated hardware configuration. No other host's disk UUIDs are reused.
Put your SSH **public** key in `hosts/server/admin.pub` before relying on SSH;
without it (or an existing authorized key), remote login is unavailable. Never put
a private key or Tailscale auth key in the repository. Existing local passwords
are preserved; provision a login/sudo password for `daniel` on a fresh installation.

```sh
make build HOST=server
make rebuild HOST=server
```

A commit or `make build` alone does not change installed packages. Run
`make rebuild HOST=server` **on the old laptop** to activate the headless profile;
omitting `HOST=server` selects `loqe` instead. Existing desktop hosts stay unchanged.

### Server development tools and dotfiles

`modules/home/server.nix` is the server's package and dotfile selector. Edit its
`imports`, `programs.neovim`, and `home.packages` to choose terminal tools without
importing the desktop Home Manager profile.

- **Fish:** login shell, reusing the existing aliases/functions and Zoxide config.
- **Starship/FZF:** prompt and fuzzy-finder integration from existing modules.
- **tmux:** existing config, Sesh and Resurrect; prefix is `Alt+s`, not `Ctrl+b`.
- **Neovim:** default editor, with `vi`/`vim` aliases. Edit
  `dotfiles/server/nvim/init.lua` for server-specific settings and keybindings.
  It keeps basic preferences without the desktop's plugin/download stack.
- **Development:** Git/GH, GCC, Make, CMake, pkg-config, Python, Node.js, Go,
  ripgrep, fd, jq, zip/unzip, nixfmt, and nixd.

Home Manager generates `~/.config/fish/config.fish`, `~/.config/nvim/init.lua`,
and `~/.config/tmux/tmux.conf`; edit their source modules, not these managed files.
Existing unmanaged files get a `.hm-backup` suffix. If that backup already exists,
activation stops rather than overwriting it; review the conflict before retrying.
The current desktop's live dotfiles are not copied or modified.

On the server, apply the updated checkout with `make rebuild HOST=server`, then
reconnect SSH for the Fish login shell. Home Manager runs with the rebuild; do not
use the desktop-only `make dotfile` or `make setup` targets.

### SSH from the local network

SSH accepts keys only and denies root login. The server allows TCP port 22 from
LAN IPv4 subnet `192.168.100.0/24` and from the Tailscale interface, not globally.
If your LAN uses another subnet, adjust the rule in `hosts/server/configuration.nix`.
This uses the existing iptables firewall; no package changes are needed.

On the client, reuse an existing SSH key. If you do not have one, create it with
`ssh-keygen -t ed25519` (do not overwrite an existing key). Copy only its `.pub` file
to `hosts/server/admin.pub` in the checkout **on the server**, using its local
console or removable storage. If no key is authorized yet, `ssh-copy-id` cannot
bootstrap access because password login is disabled.

After activating the server configuration, find its LAN IPv4 address locally:

```sh
ip -br -4 addr
```

From another computer on that LAN, replace `SERVER_LAN_IP` with that address:

```sh
ssh -i ~/.ssh/id_ed25519 daniel@SERVER_LAN_IP
```

Use your actual private-key path if different. LAN SSH does not require Tailscale
login or router port forwarding. For Tailscale access, run `sudo tailscale up` on
the server, then use its Tailscale IP from an authorized tailnet peer. This uses
OpenSSH, not Tailscale SSH; tailnet policy must allow the connection.

Initial activation needs local console access. Connect networking locally
(`sudo nmtui` for Wi-Fi), and keep the console available until SSH login works.

Until the laptop's hardware file exists, building the real host and `make check`
fail NixOS's missing-root-filesystem assertion. No fake root device is supplied.
These focused checks work without laptop-specific hardware:

```sh
nix eval --raw "path:$PWD#checks.x86_64-linux.server.drvPath"
bash tests/hardware.sh
```

## Sandboxed agent

The Home Manager profile installs `agent-sandbox`, its `srt` runtime, and the
Linux sandbox dependencies. Use Prime Agent directly or through the optional
sandbox alias:

```sh
prime-agent       # normal access
agent              # equivalent to: asb -p git -- prime-agent
agent --resume     # arguments are forwarded to Prime Agent
```

The `git` sandbox profile permits work in the current repository while limiting
home-directory, secret, and network access.

## TypeSafe (Jev) in Pi

Home Manager installs `modules/home/dev/ai/ai/pi/extensions/jev.ts` as
`~/.pi/agent/extensions/jev.ts`, adding the **TypeSafe (Jev)** login provider and
`jev` tool. Apply through your normal rebuild, then `/reload` in Pi. To try it
before activation, launch from this checkout:

```sh
pi -e ./modules/home/dev/ai/ai/pi/extensions/jev.ts
```

Get a key from <https://console.typesafe.ai/keys>, then run in Pi:

```text
/login typesafe-ai
```

Enter the key in the secret prompt, not chat. Pi saves it in its user auth store;
the tool uses it immediately, without a restart. `/logout typesafe-ai` removes
the saved key. `TYPESAFE_API_KEY` remains an optional fallback; saved keys take
precedence. Never put keys in Git, Nix expressions, or `sessionVariables`.

Keep your usual chat model. Ask: **Use jev to judge whether “Production is down.
Help now.” expresses urgency.** The tool accepts `state`, typed `questions`, and
optional `model` (default `jev-latest`). Only supplied arguments go to TypeSafe.
Calls use your TypeSafe account, time out after 30 seconds, and do not auto-retry.
Responses over 50 KiB or 2000 lines are rejected; use smaller batches.

### Local Jev feedback

After applying the Home Manager configuration and `/reload`, run a new `jev`
call, then use `/jev-feedback`. Choose one question from the latest successful
call, review its JSON, remove sensitive content, select the correct answer, and
confirm saving. Escape/cancel saves nothing. An interactive UI is required.

**Redaction is manual. Remove secrets, credentials, and personal data from every
field before confirming; preserve the meaning of the example.** No automatic
redactor can guarantee this. The command never uploads feedback or reads Pi
session history. Normal `jev` calls still send their supplied inputs to TypeSafe.

Approved examples append to `~/.pi/agent/jev-feedback/samples.jsonl` (under
`PI_CODING_AGENT_DIR` instead when overridden). The directory is private (`0700`)
and the file is private (`0600`), outside this checkout by default. Symlinks,
hard-linked files, and unsafe permissions/ownership are refused, not repaired.
Keep this runtime dataset out of Git and Nix sources. If a write fails, inspect
the file before retrying; an incomplete final record may need manual repair.

Each JSON line contains `model`, redacted `state`, one `question`, scalar Jev
`prediction`, and your `expected` answer. Noul labels are booleans, Choice labels
are option keys, and Score labels are zero-based rubric levels. Feedback is saved
only after explicit labeling and approval; an unreviewed prediction is never a
training label. Samples are limited to 50 KiB; the editor also limits 2000 lines.

Only the latest completed successful interactive call is retained in memory.
Reloads, session changes, tree navigation, and exit clear it. There is no full-chat
logging, automatic retrieval, downstream trainer, or Jev fine-tuning in this step.

### Jev checks

Checks use the installed Home Manager Pi package, with no npm install or real key:

```sh
node --test tests/jev.mjs
tsc --project modules/home/dev/ai/ai/pi/extensions/tsconfig.json
```

The regression check covers Pi's login menu, in-memory login/logout, key fallback,
mocked Jev requests, and feedback approval, labels, lifecycle clearing, and private
storage. Feedback tests use temporary directories and synthetic data only. No paid
calls. API: <https://docs.typesafe.ai/api>.

## Layout

- `flake.nix`: inputs and exported NixOS/Home Manager configurations
- `hosts/default`, `hosts/loqe`: physical workstation configurations
- `hosts/server`: minimal laptop-server host and local provisioning files
- `hosts/wsl`: NixOS-WSL configuration
- `modules/system`: reusable desktop NixOS modules
- `modules/server`: standalone minimal laptop-server module
- `modules/home`: Home Manager modules
- `modules/home/server.nix`: server development packages and dotfile selection
- `dotfiles/server/nvim/init.lua`: portable server Neovim settings
- `tests/server.nix`: server host, developer profile, headless services, and SSH/firewall check
- `tests/hardware.sh`: hardware generation host-selection and failure-safety check
- `dotfiles`: application configuration copied or linked by the modules
