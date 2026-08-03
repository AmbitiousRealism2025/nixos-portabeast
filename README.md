# Installed-system NixOS configuration

This is the staging tree for the working Calamares installation. It begins as
a flake wrapper around the exact live `configuration.nix` and generated
`hardware-configuration.nix` observed on 2026-08-03. Its nixpkgs input is the
immutable official release tarball that produced NixOS
`26.05.6815.531670d871c0`, rather than the same GitHub commit with different
release metadata.

It deliberately contains no Disko input, Disko app, filesystem redesign,
Btrfs/Snapper assumptions, Home Manager, Hyprland, DMS, NVIDIA policy, or
account rename. The first acceptance gate is a build that introduces no
intentional functional change.

Do not activate this staging tree merely because it evaluates. Review the
lock, build result, and diff against `/etc/nixos` first, preserve Plasma and the
previous generation, and obtain explicit confirmation before privileged writes
or activation.

## Baseline validation — 2026-08-03

- `nix flake check --no-build`: passed.
- Built output:
  `/nix/store/n7pz21rbxzpvfj12hrdyaf9i78kq4qra-nixos-system-nixos-26.05.6815.531670d871c0`.
- `/run/current-system` resolves to that exact same store path.
- No activation, profile change, bootloader write, `/etc/nixos` write, or reboot
  was performed.

The tarball contains a command-not-found database that was absent from the
Calamares evaluation source. `programs.command-not-found.enable = false` is
therefore explicit in `configuration.nix` to preserve the current effective
behavior and exact output.
