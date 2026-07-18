# Pi plugin update design

## Goal

Update Nix-managed Pi packages to current pinned npm releases and add official Ponytail plus `pi-advisor`, without changing runtime model defaults or enabling advisor calls automatically.

## Package changes

| Package | Current | Target |
|---|---:|---:|
| `pi-caveman` | 1.0.7 | 1.0.7 |
| `pi-superpowers` | 0.2.0 | 0.2.0 |
| `pi-web-access` | 0.10.7 | 0.13.0 |
| `pi-subagents` | 0.28.0 | 0.35.1 |
| `pi-lens` | 3.8.50 | 3.8.70 |
| `pi-powerline-footer` | 0.6.1 | 0.7.0 |
| `@ayulab/pi-rewind` | 0.3.1 | 0.4.6 |
| `@dietrichgebert/ponytail` | absent | 4.8.4 |
| `pi-advisor` | absent | 0.3.0 |

All package specs remain exact npm pins. Existing already-current packages remain unchanged.

## Behavior

- Official `@dietrichgebert/ponytail` supplies Pi extension and skills. Upstream default mode remains `full`.
- `pi-advisor` supplies strategic advisor tool and commands.
- No Nix-managed `advisor.json` is created. Advisor remains disabled until explicitly enabled, for example `/advisor on openai-codex/gpt-5.6-sol`.
- Existing Pi default remains `openai-codex/gpt-5.6-sol`.
- No new model declaration or provider credential is added.
- No package is installed imperatively into Nix-managed settings.

## Compatibility and release impact

- Target packages use current `@earendil-works/*` Pi peer packages and support Pi 0.80.x.
- `pi-powerline-footer` 0.7.0 declares Pi compatibility `>=0.74.0 <0.81.0`.
- `pi-web-access` 0.13.0 removes deprecated `code_search`, adds OpenAI subscription web search, and includes SSRF, path traversal, curator injection, and dependency security fixes.
- `pi-subagents` 0.35.1 adds native supervisor coordination, agent administration, stricter acceptance semantics, read-only role metadata, and numerous async/runtime fixes.
- `pi-lens` 3.8.70 contains extensive diagnostics, process cleanup, LSP, and security-scanning fixes.
- Ponytail and advisor are MIT-licensed, dependency-light Pi packages. Ponytail modifies prompt behavior; advisor can make additional model calls only after activation.

## Supply-chain review

Before mutation, fetch exact npm tarballs and inspect:

- package name/version and `pi` manifest;
- lifecycle scripts and dependency/peer-dependency declarations;
- license and repository provenance;
- extension entrypoints for unexpected install hooks, command execution, network access, or credential handling;
- changelogs for breaking changes and security fixes.

Use exact versions from npm registry metadata. Do not use floating tags or unpinned Git refs.

## Validation

1. Verify every target version against npm registry metadata.
2. Install exact package set into an isolated temporary Pi agent directory using Pi or npm package resolution, never active user config.
3. Load extensions/resources against current Pi and report startup diagnostics.
4. Confirm expected custom agents and harness skills remain discoverable.
5. Confirm Ponytail skills/extension and advisor extension load.
6. Run `nixfmt --check`, `nix flake check --no-build`, Home Manager activation evaluation, and activation package build.
7. Inspect generated `settings.json` for exact package pins and unchanged default provider/model.
8. Review diff and preserve pre-existing `flake.lock` changes untouched.

## Safety

- No advisor activation or model call during validation.
- No push, deployment, secret access, or destructive Git action.
- Preserve existing `flake.lock` changes and unrelated work.
- Keep update limited to package pins unless compatibility evidence requires a separately approved change.
