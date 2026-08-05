#!/usr/bin/env bash
set -euo pipefail
umask 077

export PATH="@privateRuntime@:@runtimePath@:$PATH"

config_dir="${CLAUDEX_CONFIG_DIR:-$HOME/.config/claudex}"
env_file="$config_dir/env"
auth_dir="$config_dir/codex-accounts"
proxy_config="$config_dir/cliproxyapi.yaml"

install -d -m 0700 "$config_dir" "$auth_dir" "$config_dir/skills/usage-limit"

proxy_token=""
if [[ -r "$env_file" ]]; then
  # This is a private, user-owned shell environment file managed by Claudex.
  # Match upstream's preservation behavior so a generated key survives rebuilds.
  # shellcheck disable=SC1090
  source "$env_file"
  proxy_token="${CLAUDEX_PROXY_TOKEN:-}"
fi
if [[ -z "$proxy_token" ]]; then
  proxy_token=$(openssl rand -hex 32)
fi
[[ "$proxy_token" != *$'\n'* && "$proxy_token" != *$'\r'* ]] || {
  echo 'claudex-setup: local proxy key contains an unsupported newline' >&2
  exit 1
}

preserved_env=$(mktemp "$config_dir/.env-preserved.XXXXXX")
if [[ -r "$env_file" ]]; then
  awk '
    /^[[:space:]]*(export[[:space:]]+)?(CLAUDEX_PROXY_TOKEN|CLAUDEX_PROXY_URL|CLAUDEX_PROXY_CONFIG|CLAUDEX_PROXY_BIN|CLAUDEX_CODEX_AUTH_DIR|CLAUDEX_AUTO_UPDATE|CLAUDEX_CLAUDE_AUTO_UPDATE|CLAUDEX_SKIP_CLAUDE_UPDATE)[[:space:]]*=/ { next }
    { print }
  ' "$env_file" > "$preserved_env"
fi

env_tmp=$(mktemp "$config_dir/.env.XXXXXX")
{
  printf 'CLAUDEX_PROXY_TOKEN=%q\n' "$proxy_token"
  printf 'CLAUDEX_PROXY_URL=%q\n' 'http://127.0.0.1:8318'
  printf 'CLAUDEX_PROXY_CONFIG=%q\n' "$proxy_config"
  printf 'CLAUDEX_PROXY_BIN=%q\n' '@proxyBin@'
  printf 'CLAUDEX_CODEX_AUTH_DIR=%q\n' "$auth_dir"
  printf 'CLAUDEX_AUTO_UPDATE=%q\n' off
  printf 'CLAUDEX_CLAUDE_AUTO_UPDATE=%q\n' off
  printf 'CLAUDEX_SKIP_CLAUDE_UPDATE=%q\n' 1
  cat "$preserved_env"
} > "$env_tmp"
chmod 0600 "$env_tmp"
mv -f "$env_tmp" "$env_file"
rm -f "$preserved_env"

json_token=$(printf '%s' "$proxy_token" | jq -Rs '.')
json_auth_dir=$(printf '%s' "$auth_dir" | jq -Rs '.')
proxy_tmp=$(mktemp "$config_dir/.cliproxyapi.XXXXXX")
{
  printf 'host: "127.0.0.1"\n'
  printf 'port: 8318\n'
  printf 'tls:\n  enable: false\n'
  printf 'remote-management:\n'
  printf '  allow-remote: false\n'
  printf '  secret-key: ""\n'
  printf '  disable-control-panel: true\n'
  printf '  disable-auto-update-panel: true\n'
  printf 'auth-dir: %s\n' "$json_auth_dir"
  printf 'api-keys:\n  - %s\n' "$json_token"
  printf 'debug: false\n'
  printf 'logging-to-file: false\n'
  printf 'usage-statistics-enabled: false\n'
  printf 'pprof:\n  enable: false\n  addr: "127.0.0.1:8316"\n'
  printf 'plugins:\n  enabled: false\n'
  printf 'request-retry: 3\n'
  printf 'max-retry-credentials: 1\n'
  printf 'max-retry-interval: 5\n'
  printf 'transient-error-cooldown-seconds: 1\n'
  printf 'streaming:\n  keepalive-seconds: 15\n  bootstrap-retries: 2\n'
  printf 'ws-auth: true\n'
} > "$proxy_tmp"
chmod 0600 "$proxy_tmp"
mv -f "$proxy_tmp" "$proxy_config"

install -m 0755 @share@/statusline "$config_dir/statusline"
install -m 0755 @share@/usage-limit "$config_dir/usage-limit"
install -m 0755 @share@/codex-session "$config_dir/codex-session"
install -m 0644 @share@/preload.cjs "$config_dir/preload.cjs"
install -m 0644 @share@/skill-bridge.cjs "$config_dir/skill-bridge.cjs"
install -m 0755 @share@/self-update "$config_dir/self-update"
install -m 0644 @share@/skills/usage-limit/SKILL.md "$config_dir/skills/usage-limit/SKILL.md"

printf -v statusline_command '%q %q' '@bashBin@' "$config_dir/statusline"
settings_tmp=$(mktemp "$config_dir/.settings.XXXXXX")
jq --arg command "$statusline_command" '.statusLine.command = $command' \
  @share@/settings.json > "$settings_tmp"
chmod 0600 "$settings_tmp"
mv -f "$settings_tmp" "$config_dir/settings.json"

printf '%s\n' '@version@' > "$config_dir/.nixos-managed-version"
chmod 0600 "$config_dir/.nixos-managed-version"

echo 'Claudex private runtime configuration is ready.'
echo 'Run `claudex --auth-status`, then launch with `claudex`.'
