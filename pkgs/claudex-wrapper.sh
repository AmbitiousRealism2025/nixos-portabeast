#!/usr/bin/env bash
set -euo pipefail

export CLAUDEX_CONFIG_DIR="${CLAUDEX_CONFIG_DIR:-$HOME/.config/claudex}"
export PATH="@privateRuntime@:@runtimePath@:$PATH"

managed_version=""
if [[ -r "$CLAUDEX_CONFIG_DIR/.nixos-managed-version" ]]; then
  IFS= read -r managed_version < "$CLAUDEX_CONFIG_DIR/.nixos-managed-version" || managed_version=""
fi
if [[ "$managed_version" != "@version@" || ! -r "$CLAUDEX_CONFIG_DIR/env" ]]; then
  @setup@ >/dev/null
fi

exec @launcher@ "$@"
