# AMD NixOS fresh-install handoff

This repository is the NixOS source for both machines. It is not an Omarchy
installer. The existing `nixosConfigurations.nixos` output remains the
ThinkPad P1 Gen 4i recovery configuration. Add the AMD machine as a second
flake output. Do not convert the ThinkPad output in place.

## Important discrepancy found during the audit

The machine available during this audit identifies through DMI as a Lenovo
ThinkPad P1 Gen 4i with an Intel i7-11850H, Intel integrated graphics, and an
NVIDIA T1200. Its live `/etc/nixos` tree nevertheless contains an activated,
uncommitted AMD migration overlay. That overlay built to the exact running
system closure, so it is useful migration evidence, but it is not an
authoritative hardware configuration for the new AMD drive.

The AMD overlay was preserved locally during this audit instead of being
committed over the ThinkPad configuration. Its intentional changes were:

- Remove the separate NVIDIA package input, NVIDIA kernel selection, PRIME
  offload configuration, NVIDIA bus IDs, and NVIDIA X server driver.
- Enable `hardware.graphics` and use
  `services.xserver.videoDrivers = [ "amdgpu" ];`.
- Replace Intel microcode with AMD microcode. The overlay comments identify
  the target as a Ryzen 5 7430U with Barcelo graphics.
- Add automatic weekly Nix garbage collection, store optimisation, a 20 GiB
  minimum-free threshold, and a 60 GiB maximum-free threshold.
- Add an LG C2 rule at `3840x2160@60.00`, position `0x0`, scale `1.5`, and
  change the LG UltraGear rule to `2560x1440@143.93`.
- Advance the Albion source from `63c084c` to `ae23d12` with its corresponding
  fixed hash.

Recheck the actual AMD CPU, GPU, display connector names, and monitor
descriptions on the new installation. Comments from the old overlay are not a
substitute for hardware discovery.

## Required repository shape

Create an explicit AMD output such as `nixosConfigurations.amd`. A reasonable
layout is:

```text
hosts/
  thinkpad/
    configuration.nix
    hardware-configuration.nix
  amd/
    configuration.nix
    hardware-configuration.nix
modules/
  common.nix
```

Keep these settings host-specific:

- ThinkPad: Intel microcode, NVIDIA T1200 and PRIME policy, NVIDIA kernel
  package policy, laptop display and clamshell behavior, and its disk layout.
- AMD: AMD microcode, `amdgpu`, the discovered AMD graphics and power policy,
  AMD monitor rules, and the new drive layout.
- Common: user accounts, Home Manager modules, shell and application packages,
  themes, networking, Nix settings, and services that are useful on both
  machines.

The host split should be a structural refactor only. First prove that the
ThinkPad output still builds, then add and prove the AMD output.

## Fresh-drive rules

Do not copy the committed `hardware-configuration.nix` onto the new drive. Do
not reuse its root or boot filesystem UUIDs, swapfile or swap-device values,
resume device, resume offset, initrd modules, or bootloader target.

From the NixOS installer:

1. Partition, format, and mount the new drive under `/mnt`.
2. Run `nixos-generate-config --root /mnt`.
3. Preserve the generated `/mnt/etc/nixos/hardware-configuration.nix` and move
   its declarations into `hosts/amd/hardware-configuration.nix` in the clone.
4. Confirm the values against `lsblk -f`, `findmnt -R /mnt`, `lspci -nnk`, and
   `free -h` before installing.
5. If hibernation is wanted, configure swap and resume for this drive only.
   Recalculate any swapfile resume offset after the final filesystem and
   swapfile exist.

Clone the public repository into the installer environment, create the AMD
host output, and validate it before installation:

```sh
git clone https://github.com/AmbitiousRealism2025/nixos-portabeast.git
cd nixos-portabeast
nix flake check --no-build
nix build .#nixosConfigurations.nixos.config.system.build.toplevel \
  --no-link --print-out-paths
nix build .#nixosConfigurations.amd.config.system.build.toplevel \
  --no-link --print-out-paths
```

After the `amd` output exists and both builds pass, install only the AMD
output:

```sh
sudo nixos-install --flake .#amd
```

Never install or activate the ThinkPad output on the AMD machine. After the
first boot, use a dry activation for later changes and keep the previous boot
generation available:

```sh
sudo nixos-rebuild dry-activate --flake .#amd
sudo nixos-rebuild switch --flake .#amd
```

## Access and public-repository warning

This repository is public. Never commit private keys, access tokens, password
hashes, `.env` files, browser profiles, login sessions, application state, or
generated credentials.

The flake currently consumes
`AmbitiousRealism2025/coding-tool-update-check`, which the repository ledger
describes as private. A clean AMD install therefore needs GitHub credentials
that can read that input, or the checker must be made public, removed, or made
optional before an unauthenticated build can work. Resolve that deliberately;
do not embed a token in the flake URL or commit credentials.

## Audit status on 2026-08-31

- The public `main` history was preserved.
- The ten pending Portabeast commits from `agent/install-prime-agent` were
  merged normally into the review branch.
- Only the `codex-desktop-linux` lock node was advanced after the old mutable
  desktop artifact stopped reproducing. It now builds the versioned Linux
  package `26.825.51511`.
- `nix flake check --no-build` evaluates successfully.
- The complete ThinkPad output builds successfully at
  `/nix/store/k9i5kj0aqcabg26q8bmkwfbi1lwcsmyq-nixos-system-nixos-26.05.6815.531670d871c0`.
- No output from this review branch was activated.

