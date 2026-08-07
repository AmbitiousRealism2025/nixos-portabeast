#!/usr/bin/env bash
set -euo pipefail

repo_arg=${1:-.}
configuration=${2:-nixos}
repo=$(realpath -- "$repo_arg")

git -c safe.directory="$repo" -C "$repo" rev-parse --is-inside-work-tree >/dev/null

echo "Repository status:"
git -c safe.directory="$repo" -C "$repo" status -sb

echo
echo "Checking patch whitespace..."
git -c safe.directory="$repo" -C "$repo" diff --check

nix_flags=(--extra-experimental-features "nix-command flakes")

echo
echo "Evaluating flake outputs..."
nix "${nix_flags[@]}" flake check "$repo" --no-build

echo
echo "Building NixOS configuration '$configuration' without activation..."
build_output=$(
  nix "${nix_flags[@]}" build \
    "$repo#nixosConfigurations.$configuration.config.system.build.toplevel" \
    --no-link --print-out-paths
)
printf 'Full build output: %s\n' "$build_output"

run_gitleaks() {
  if command -v gitleaks >/dev/null 2>&1; then
    gitleaks "$@"
  else
    nix "${nix_flags[@]}" shell nixpkgs#gitleaks -c gitleaks "$@"
  fi
}

echo
echo "Scanning the current tree for secrets..."
run_gitleaks dir --no-banner --redact "$repo"

echo
echo "Scanning complete Git history for secrets..."
export GIT_CONFIG_COUNT=1
export GIT_CONFIG_KEY_0=safe.directory
export GIT_CONFIG_VALUE_0="$repo"
run_gitleaks git --no-banner --redact --log-opts="--all" "$repo"

echo
echo "Validation passed without activation."
