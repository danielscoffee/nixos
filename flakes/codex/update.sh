#!/usr/bin/env bash
# Pin sources.json to the latest openai/codex release. Hashes come from the
# sha256 digests GitHub publishes per asset, so nothing is downloaded here;
# Nix still verifies every tarball when it fetches it.
set -euo pipefail
shopt -s inherit_errexit
cd "$(dirname "$0")"

release=$(curl -fsSL https://api.github.com/repos/openai/codex/releases/latest)
tag=$(jq -r .tag_name <<<"$release")
version=${tag#rust-v}

sri() {
  local digest
  digest=$(jq -r --arg name "$1" '.assets[] | select(.name == $name) | .digest' <<<"$release")
  if [[ $digest != sha256:* ]]; then
    echo "update.sh: no sha256 digest for $1 in $tag" >&2
    exit 1
  fi
  nix hash convert --hash-algo sha256 --to sri "${digest#sha256:}"
}

platform() {
  local codex host
  codex=$(sri "codex-$1.tar.gz")
  host=$(sri "codex-code-mode-host-$1.tar.gz")
  jq -n --arg target "$1" --arg codex "$codex" --arg host "$host" \
    '{target: $target, codex: $codex, "codex-code-mode-host": $host}'
}

x86_64=$(platform x86_64-unknown-linux-musl)
aarch64=$(platform aarch64-unknown-linux-musl)
jq -n --arg version "$version" --argjson x86_64 "$x86_64" --argjson aarch64 "$aarch64" \
  '{version: $version, platforms: {"x86_64-linux": $x86_64, "aarch64-linux": $aarch64}}' >sources.json
echo "codex $version"
