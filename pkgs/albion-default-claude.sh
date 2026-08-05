#!/usr/bin/env bash
set -euo pipefail

# Keep ordinary version probes usable before Albion credentials are created.
if [[ $# -eq 1 && $1 == --version ]]; then
  exec @claudeCode@/bin/claude "$@"
fi

exec @albionLauncher@ "$@"
