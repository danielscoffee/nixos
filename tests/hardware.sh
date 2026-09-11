#!/usr/bin/env bash
set -euo pipefail

makefile="$(cd "$(dirname "$0")/.." && pwd)/Makefile"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"
mkdir -p bin hosts/server hosts/default

# Stub privilege escalation and generation; never inspect real hardware.
cat >bin/sudo <<'SH'
#!/bin/sh
set -eu
[ "$1" = nixos-generate-config ]
[ "$2" = --show-hardware-config ]
if [ "${FAIL_GENERATION:-0}" = 1 ]; then
  printf 'partial output\n'
  exit 1
fi
printf '{ generated = true; }\n'
SH
chmod +x bin/sudo
export PATH="$work/bin:$PATH"

printf 'keep default\n' >hosts/default/hardware-configuration.nix
printf 'old server\n' >hosts/server/hardware-configuration.nix
make --no-print-directory -f "$makefile" hardware HOST=server >/dev/null
grep -qx '{ generated = true; }' hosts/server/hardware-configuration.nix
grep -qx 'keep default' hosts/default/hardware-configuration.nix
cp hosts/server/hardware-configuration.nix expected

if FAIL_GENERATION=1 make --no-print-directory -f "$makefile" hardware HOST=server >/dev/null 2>&1; then
	printf 'Expected hardware generation to fail\n' >&2
	exit 1
fi
cmp expected hosts/server/hardware-configuration.nix
mv hosts/server/hardware-configuration.nix original
ln -s "$work/original" hosts/server/hardware-configuration.nix
if make --no-print-directory -f "$makefile" hardware HOST=server >/dev/null 2>&1; then
	printf 'Expected symlinked hardware configuration to be rejected\n' >&2
	exit 1
fi
test -L hosts/server/hardware-configuration.nix
cmp expected original
printf 'hardware target: host selection, failure preservation, and symlink protection passed\n'
