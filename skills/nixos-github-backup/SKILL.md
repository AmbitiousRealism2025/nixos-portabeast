---
name: nixos-github-backup
description: Safely synchronize, document, validate, and publish a declarative NixOS configuration to GitHub. Use for backing up /etc/nixos, refreshing a NixOS recovery repository, recording significant system changes in a running README ledger, auditing a flake before publication, or preparing a reproducible NixOS restore branch or pull request.
---

# NixOS GitHub Backup

Preserve the accepted NixOS configuration and its history without confusing a
GitHub backup with activation of the running machine.

## 1. Establish scope

1. Identify the live source tree, publishing checkout, flake configuration
   name, remote, default branch, and repository visibility.
2. Inspect `git status -sb`, relevant diffs, remotes, and recent history in both
   trees before writing anything.
3. Treat uncommitted files as user work. Classify them as intended,
   superseded, generated, or unrelated. Preserve superseded work in a named Git
   stash until the synchronization is accepted.
4. Keep machine repositories separate unless the user explicitly requests a
   shared multi-host flake.

If the publishing checkout and `/etc/nixos` share history, fetch the live tree
as a local remote and merge it. Use a one-command `safe.directory` override for
root-owned `/etc/nixos`; do not mutate global Git configuration. Never use a
hard reset, force push, or history replacement merely to make the trees match.

## 2. Protect private data

1. Check whether the remote is public or private.
2. Scan both the current worktree and complete Git history for credentials
   before publishing. Use `scripts/validate_nixos_backup.sh` for the final scan.
3. Never commit password hashes, private keys, API tokens, authentication keys,
   `.env` files, application sessions, or generated credential files.
4. Treat filesystem UUIDs, public SSH keys, hostnames, usernames, and device
   identifiers as machine metadata. Retain them only when needed for recovery
   and appropriate for the repository's visibility.
5. Document important state that is intentionally excluded, such as browser
   profiles, password-vault data, Tailscale identity, and runtime-generated
   credentials.

## 3. Synchronize conservatively

1. Create an `agent/<description>` branch from the remote default branch.
2. Preserve accepted Git history through a normal merge when possible.
3. Include declarative modules, package expressions, patches, required assets,
   `flake.nix`, and `flake.lock`.
4. Exclude one-shot activation scripts, build results, editor state, and local
   secrets unless a script is intentionally reusable and reviewed.
5. Preserve exact input locks by default. Update only a named input when the
   user requested or approved the update, then identify the resulting closure
   difference.

Do not copy a GitHub candidate into `/etc/nixos` or activate it as an implicit
part of making a backup.

## 4. Maintain the README ledger

Read `references/readme-ledger.md` before editing the repository README.

- Keep stable recovery instructions separate from the chronological ledger.
- Add a ledger entry in the same commit as every significant configuration
  change.
- Record what changed, why it matters, validation performed, and whether the
  candidate was activated.
- Update the current snapshot after a successful full build or activation.
- Summarize related small commits as one milestone; rely on Git history for
  file-level detail.

## 5. Validate without activation

Run:

```sh
skills/nixos-github-backup/scripts/validate_nixos_backup.sh <repo> <configuration>
```

The script performs whitespace validation, flake evaluation, a complete NixOS
system build, and current-tree plus full-history secret scans. It performs no
activation, profile change, bootloader write, or reboot.

When the candidate intentionally changes packages, compare its closure against
`/run/current-system` and confirm that unexpected changes are absent. A cached
build is useful but does not prove a mutable upstream download remains
reproducible; refreshed binary inputs must complete their fetch successfully.

## 6. Publish through review

1. Review the final status and diff.
2. Stage only the intended files explicitly.
3. Commit with a terse description.
4. Push the branch with tracking.
5. Open a draft pull request describing scope, reason, impact, validation, and
   activation state.
6. Confirm the local and remote branch commit IDs match.

Do not claim `main` is current until the pull request is merged. A pushed branch
is already an off-machine backup, but say clearly where it lives.

## 7. Handle activation separately

Activate only when the user explicitly requests it. Build first, review a dry
activation, use local PolicyKit authentication for privileged work, retain the
previous boot generation, and test the affected behavior. After acceptance,
commit the live tree and add or amend the next ledger entry so the repository
distinguishes built, activated, and user-tested states.

## Handoff

Report:

- repository visibility, branch, commit, and pull-request link;
- live source commit synchronized;
- validation commands and full build output;
- secret-scan result;
- whether activation occurred;
- remaining dirty work or recoverable stashes;
- state excluded from the declarative backup.
