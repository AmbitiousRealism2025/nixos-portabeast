# nixos-portabeast

Private, declarative NixOS configuration for the **Portabeast**, a ThinkPad P1
Gen 4. This repository is the off-machine backup of the working `/etc/nixos`
configuration and is intentionally separate from the mini PC configuration.

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
