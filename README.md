# nixos-portabeast

Private, declarative NixOS configuration for the **Portabeast**, a ThinkPad P1
Gen 4. This repository is the off-machine backup of the working `/etc/nixos`
configuration and is intentionally separate from the mini PC configuration.

## Current validated snapshot

- **Last reviewed:** 2026-08-07
- **Flake configuration:** `nixos`
- **Live history synchronized through:** `b502244` (`Add Azeron Software 2.0.1`)
- **Last complete build:**
  `/nix/store/fdmv3iyxm61iixaxq7vnj5rai591y3kb-nixos-system-nixos-26.05.6815.531670d871c0`
- **Repository state:** Complete private recovery configuration on GitHub
  `main`, with Codex Desktop
  `26.803.41515` and the Zen FFmpeg compatibility fix
- **Activation state:** The repository-only Codex refresh and Zen fix have been
  built but were not activated on the running machine

## What this restores

- KDE Plasma and the UWSM-managed Hyprland/DMS desktop
- Home Manager shell, application, theme, keybinding, and monitor policy
- NVIDIA PRIME/offload, power-management, suspend, and hibernation policy
- Zram, Bluetooth, Tailscale, portals, storage integration, and device rules
- Pinned desktop and development tools, including Codex Desktop, T3 Code,
  OpenCode, Traycer, Albion/Claude, Claudex, Zen, Nemo/Yazi, Swiftpoint, and
  Azeron integrations
- The machine-specific filesystem and boot configuration in
  `hardware-configuration.nix`

Inputs and externally packaged applications are pinned by `flake.lock` and the
package definitions under `pkgs/`.

## What this does not back up

This repository does not contain home-directory data, application state,
browser profiles, login sessions, password-vault contents, Tailscale identity,
or locally generated Albion/Claudex credentials. Those remain outside the Nix
store and need their own backup or a fresh login/setup after restoration.

## Validation and activation

From the repository root, validate before activation:

```sh
nix flake check --no-build
nix build .#nixosConfigurations.nixos.config.system.build.toplevel --no-link
sudo nixos-rebuild dry-activate --flake .#nixos
```

After reviewing the dry activation, activate with:

```sh
sudo nixos-rebuild switch --flake .#nixos
```

For a clean reinstall on this same ThinkPad, compare the installer-generated
hardware configuration and disk UUIDs before replacing `/etc/nixos`. On a
different computer, generate a new `hardware-configuration.nix`; do not reuse
this machine's disk and hardware declarations unchanged.

The Git history records the accepted configuration layers and provides a useful
audit trail, but a NixOS boot generation remains the immediate local rollback
mechanism.

## README maintenance rule

Treat this README as the human-readable system ledger. Every commit that adds
or materially changes a service, driver, application source, hardware policy,
desktop workflow, security setting, or recovery requirement must update the
snapshot or ledger in the same commit. Routine formatting and internal cleanup
do not need entries.

The canonical workflow is stored in the repository's
`skills/nixos-github-backup` Codex skill.

## Significant change ledger

Entries are newest first. Git history remains the file-level audit trail.

### 2026-08-08 — Repair Albion file-edit deny rules

- **Changed:** Translate Albion's legacy path-scoped `Write(...)` deny rules to
  Claude Code's current `Edit(...)` permission namespace and fail the Albion
  package check if legacy rules return.
- **Reason:** Claude Code 2.1.222 rejected the old rules at startup, leaving the
  intended edit restrictions for environment files, secrets, SSH/AWS data,
  private keys, and credential files inactive.
- **Validated:** Warning-free Claude launch, isolated Albion build, complete
  NixOS build, closure review against the running generation, and current-tree
  plus full-history secret scans.
- **State:** Built only; an isolated activation candidate based on the exact
  running closure is ready but was not activated from the restricted build
  environment.

### 2026-08-07 — Reproducible GitHub recovery workflow

- **Changed:** Synchronized the complete accepted `/etc/nixos` history into the
  private GitHub recovery repository, refreshed Codex Desktop to `26.803.41515`,
  preserved Zen's FFmpeg 7 compatibility fix, and added the reusable
  `nixos-github-backup` Codex skill.
- **Reason:** Make the remote repository a genuine off-machine recovery source
  and ensure future significant changes are documented consistently.
- **Validated:** Flake evaluation, complete NixOS build, closure review, and
  current-tree plus full-history secret scans.
- **State:** Merged into private GitHub `main`; latest repository-only
  refinements are built but not activated.

### 2026-08-05 — Applications, development tools, and device integrations

- **Changed:** Added the dual-monitor/clamshell workflow, Nemo/Yazi, GeForce
  NOW, Java, Zed, Claude Code, Albion, Claudex, Tailscale, Swiftpoint Z3, and
  Azeron Software integrations.
- **Reason:** Complete the everyday application and peripheral environment.
- **Validated:** Incremental NixOS builds and user acceptance tests for the
  affected applications and hardware.
- **State:** Activated and persisted in the live configuration.

### 2026-08-04 — Power reliability and personalized Hyprland workflow

- **Changed:** Matched the NVIDIA 610 open-driver suspend stack, enabled working
  lid suspend and manual hibernation, made Parakeet v2 the default speech model,
  and added the Graphene theme, authentic application icons, navigation binds,
  and Apple-shaped editing shortcuts.
- **Reason:** Resolve NVIDIA resume failures while making the desktop match the
  owner's established workflow.
- **Validated:** Reboot, suspend/resume, hibernation/resume, transcription, and
  interactive desktop testing.
- **State:** Activated, user-tested, and persisted.

### 2026-08-03 — Declarative desktop foundation

- **Changed:** Adopted the Calamares baseline as a flake, enabled Zram and Home
  Manager, added the UWSM-managed Hyprland/DMS session alongside Plasma, and
  introduced Codex Desktop, Kitty, portals, NVIDIA PRIME offload, Voxtype, Zen,
  and 1Password.
- **Reason:** Establish a recoverable NixOS base and the primary Hyprland
  workstation environment without removing Plasma as a fallback.
- **Validated:** Layered builds, temporary activations, rollback preservation,
  and user testing after each major desktop layer.
- **State:** Activated and persisted through the accepted configuration history.
