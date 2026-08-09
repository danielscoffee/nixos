# NixOS configuration

Personal flake for the `default` NixOS workstation, a NixOS-WSL host, and the
`daniel` standalone Home Manager profile.

## Prerequisites

- Nix with flakes enabled
- `make`
- `sudo` for activation and hardware generation

## Validate changes

```sh
make check       # evaluate every flake output and verify formatting
make fmt         # format all Nix files
make build       # build the default system without activating it
make build-wsl   # build the WSL system without activating it
```

Run `make check` before rebuilding. CI runs the same evaluation and formatting
checks for pushes and pull requests.

## Apply the configuration

```sh
make rebuild              # activates .#default
make rebuild HOST=wsl     # activates another NixOS configuration
```

`make hardware` regenerates `hosts/default/hardware-configuration.nix` for the
current machine. Review its diff before rebuilding; hardware UUIDs are
machine-specific.

`make setup` regenerates hardware configuration, rebuilds the default host, and
copies the i3/i3status/rofi dotfiles. It is intended only for provisioning the
matching workstation.

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

## Layout

- `flake.nix`: inputs and exported NixOS/Home Manager configurations
- `hosts/default`: physical workstation configuration
- `hosts/wsl`: NixOS-WSL configuration
- `modules/system`: reusable NixOS modules
- `modules/home`: Home Manager modules
- `dotfiles`: application configuration copied or linked by the modules
