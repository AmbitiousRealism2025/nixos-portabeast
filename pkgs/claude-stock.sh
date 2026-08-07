#!/usr/bin/env bash
set -euo pipefail

# Provide an explicit, isolated escape hatch to Anthropic's stock client.
unset \
  ALBION_ACTIVE \
  ALBION_AUTH_LANE \
  ANTHROPIC_AUTH_TOKEN \
  ANTHROPIC_BASE_URL \
  ANTHROPIC_DEFAULT_HAIKU_MODEL \
  ANTHROPIC_DEFAULT_OPUS_MODEL \
  ANTHROPIC_DEFAULT_SONNET_MODEL
export CLAUDE_CONFIG_DIR="${CLAUDE_STOCK_CONFIG_DIR:-$HOME/.claude}"

exec @claudeCode@/bin/claude "$@"
