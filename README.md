# nixos-portabeast

Private, declarative NixOS configuration for the **Portabeast**, a ThinkPad P1
Gen 4. This repository is the off-machine backup of the working `/etc/nixos`
configuration and is intentionally separate from the mini PC configuration.

## Current validated snapshot

- **Last reviewed:** 2026-08-13
- **Flake configuration:** `nixos`
- **Live history synchronized through:** `b502244` (`Add Azeron Software 2.0.1`)
- **Last complete build:**
  `/nix/store/5gacx0qdcf2bnp1v8906g1d887llchqq-nixos-system-nixos-26.05.6815.531670d871c0`
- **Repository state:** Complete private recovery configuration on GitHub
  `main`, plus a validated unified ChatGPT/Codex Desktop `26.803.81509`
  update on `agent/update-chatgpt-desktop`
- **Activation state:** The Albion permission compatibility fix is activated
  and user-tested. Cursor Agent CLI is activated and user-tested with T3 Code.
  Pi 0.84.1 is activated and tested with Codex. The
  Prime Agent 0.7.2 is activated; Prime Agent 0.7.1 was user-tested with Codex
  and ZAI. The
  previous Codex Desktop Linux integration refresh and T3 Code 0.0.33 are
  activated. OpenCode CLI and Desktop 1.18.16 are activated and user-tested.
  Codex CLI 0.147.0, Cursor 3.15.19, and Cursor Agent
  2026.08.11-e8db854 are activated. Unified ChatGPT/Codex Desktop
  26.803.81509 is activated and running.

## What this restores

- KDE Plasma and the UWSM-managed Hyprland/DMS desktop
- Home Manager shell, application, theme, keybinding, and monitor policy
- NVIDIA PRIME/offload, power-management, suspend, and hibernation policy
- Zram, Bluetooth, Tailscale, portals, storage integration, and device rules
- Pinned desktop and development tools, including Codex Desktop, T3 Code,
  OpenCode, Pi, Traycer, Albion/Claude, Claudex, Zen, Nemo/Yazi, Swiftpoint,
  Prime Agent, and Azeron integrations
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

## Recovery ledger — coding-tool update checker

The checker is a declarative report generator, never a mutator: it reads the
repository and the store closure and writes only under
`~/.local/state/coding-tool-update-check/`. Nothing it produces is needed to
rebuild or activate the system, so restoring this repository is sufficient for
recovery. The checker source/tests/package live in the **private standalone
flake** `github:AmbitiousRealism2025/coding-tool-update-check` (pinned in this
repository's `flake.lock`); this repository only consumes it as a flake input
and wires the timer. To recreate or refresh the reports after a restore:

```sh
# One-shot check with release-note summarization and notifications:
coding-tools-update-check --repo-root /home/ambitiousrealism/nixos-codex-desktop --summarize

# Dry run (prints the Markdown + JSON report, writes nothing):
coding-tools-update-check --repo-root /home/ambitiousrealism/nixos-codex-desktop --dry-run --no-notify

# Machine-readable JSON of the current run (also written to latest.json):
coding-tools-update-check --repo-root /home/ambitiousrealism/nixos-codex-desktop --json | jq .

# Print the newest Markdown report without running a new check (no network):
coding-tools-update-check --show

# Force: notify even if that version was already reported (never installs anything):
coding-tools-update-check --repo-root /home/ambitiousrealism/nixos-codex-desktop --force

# Offline run (installed vs declared only, no network):
coding-tools-update-check --repo-root /home/ambitiousrealism/nixos-codex-desktop --offline --no-notify
```

Monitored tools (exactly the requested set): Codex CLI and Codex Desktop, T3
Code, Cursor (GUI) and the Cursor Agent CLI, Pi, and Prime Agent. OpenCode,
Claude Code, Albion and Claudex are not monitored; OpenCode is only the
release-note summarization runtime.

- `latest.md` / `latest.json` are the newest report; `reports/` keeps the last
  30 dated reports (override with `--retention`); report filenames carry a
  microsecond timestamp so back-to-back runs never overwrite each other.
- `state.json` remembers which upstream versions were already notified, so the
  same version is never reported twice. A version is only marked as notified
  after `notify-send` actually delivered the notification; `--force` bypasses
  the suppression without installing or caching anything.
- If every upstream check fails, one concise failure notification is sent;
  partial errors are only recorded in the report. Success notifications
  (`--notify-success`) are off by default.
- If a report is accidentally deleted, the next timer run regenerates it; no
  other state needs manual repair.
- The Home Manager timer/service is defined in
  `home/ambitiousrealism/update-checker.nix` (`services.codingToolsUpdateCheck`);
  it persists across rebuilds and activations once enabled. Its options
  (`summarize`, `notify`, `notifyOnSuccess` — the latter default false, and
  `onCalendar` — default `"daily"`) are wired into the actual service flags
  and timer, and the service unit requests network-online ordering where
  available. The timer stays randomized (`RandomizedDelaySec`, default 6h) and
  persistent (`Persistent = true`).
- Summarization uses the exact runtime model `opencode/deepseek-v4-flash-free`
  and refuses to substitute any other model: the model is verified with
  `opencode models` before each summarization, and a model failure is reported
  clearly while the deterministic report remains valid.
- Reports carry approximate prompt/output/total token estimates (~4
  chars/token heuristic, labelled as such) and a malformed (non-JSON-object)
  model response triggers exactly one bounded retry with the identical prompt;
  hard failures are never retried.

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

### 2026-08-13 — Refresh reported coding tools

- **Changed:** Update Codex CLI to 0.147.0, Cursor to 3.15.19, Cursor Agent to
  `2026.08.11-e8db854`, and Prime Agent plus its Python runtime to 0.7.2.
- **Reason:** Apply the four updates reported by the declarative coding-tool
  update checker without advancing the OS-wide nixpkgs pin.
- **Validated:** Exact upstream artifacts and hashes, individual package builds
  and version checks, full NixOS build, closure comparison, dry activation,
  current-tree and full-history secret scans, and zero failed system or user
  units after activation.
- **State:** Activated as the current NixOS generation. Interactive application
  workflows remain to be user-tested.

### 2026-08-11 — Add Herdr agent multiplexer

- **Changed:** Pin Herdr `v0.7.5` through its official Nix flake and expose the
  `herdr` command system-wide.
- **Reason:** Add a persistent terminal workspace manager for coordinating the
  installed Codex, Claude, Pi, OpenCode, Cursor, Grok, and other coding agents.
- **Validated:** Official release tag and flake outputs, source build,
  executable version, complete NixOS build, closure comparison, and secret
  scans.
- **State:** Built only; activation and interactive agent-session testing
  remain pending.

### 2026-08-11 — Add Chrome for Keychron Launcher

- **Changed:** Install Google Chrome 151.0.7922.71, add a dedicated Keychron
  Launcher menu entry, and grant the active local session access to Keychron
  vendor `3434` raw-HID devices through a narrowly scoped udev rule.
- **Reason:** Enable the Chrome WebHID connection required by Keychron's
  browser-based keyboard configuration utility on Linux.
- **Validated:** Chrome package evaluation and executable name, desktop-entry
  generation, udev-rule evaluation, complete NixOS build, and secret scans.
- **State:** Built only; activation, keyboard reconnect, and Launcher device
  pairing remain pending.

### 2026-08-11 — Add Satty screenshot and annotation workflow

- **Changed:** Replace the basic region-only capture helper with a
  Grim/Slurp/Satty workflow for annotated region, full-display, and active-window
  screenshots. Completed captures are saved under `Pictures/Screenshots` and
  copied to the Wayland clipboard.
- **Reason:** Provide a polished, Wayland-native screenshot tool with arrows,
  text, highlighting, cropping, and blur under Hyprland.
- **Validated:** Nix evaluation, generated Satty configuration, shell helper,
  declarative keybindings, complete NixOS build, and secret scans.
- **State:** Built only; activation and interactive screenshot tests remain
  pending.

### 2026-08-11 — Update to unified ChatGPT/Codex Desktop

- **Changed:** Advance `codex-desktop-linux` from `d00ee708` to `76ea570f`,
  updating the converted official OpenAI desktop application from
  `26.803.41515` to `26.803.81509`. The application launcher is now named
  ChatGPT and retains the pinned Codex CLI path and Linux integration.
- **Reason:** Adopt OpenAI's unified desktop application containing Chat,
  Work, and Codex while continuing to use the community Linux compatibility
  layer because OpenAI does not publish a native Linux package.
- **Validated:** Named-input-only lock update, official DMG hash and build
  provenance, executable launcher, ChatGPT desktop metadata, pinned Codex CLI
  path, complete NixOS build, and closure comparison.
- **State:** Activated and running; the stale previous-version process was
  closed and the new ChatGPT window was verified under Hyprland.

### 2026-08-11 — Refresh Cursor Agent, expose OpenCode, and document shortcuts

- **Changed:** Replace the May 16 nixpkgs Cursor Agent with Cursor's official
  August 4 release, rebuild T3 Code against it, promote OpenCode CLI 1.18.16 to
  the system PATH, and add `HYPRLAND_SHORTCUTS.md` from the declarative
  bindings.
- **Reason:** Make OpenCode available in ordinary shells and address T3's
  Cursor ACP-only `Upgrade your plan to continue` response with the current
  upstream CLI. The same paid Pro+ account works in Cursor Desktop and direct
  Cursor Agent requests; its login, model catalog, and subscription metadata
  are healthy, while the failure is confined to the older ACP path used by T3.
- **Validated:** Official Cursor installer URL and archive hash, package install
  check, Cursor version/login/Grok High Fast request, OpenCode PATH version,
  T3 package rebuild, complete NixOS build, and closure comparison limited to
  Cursor Agent.
- **State:** Activated and user-tested; Cursor and OpenCode both work after
  restarting into the new environment.

### 2026-08-10 — Update OpenCode CLI and Desktop to 1.18.16

- **Changed:** Pin the official OpenCode 1.18.16 CLI archive and Desktop
  AppImage with their verified release hashes. The CLI wrapper preserves its
  embedded Bun standalone payload byte-for-byte and invokes it with Nix's
  dynamic loader.
- **Reason:** Update both OpenCode interfaces together from CLI 1.15.10 and
  Desktop 1.18.12 to the latest stable release, including configuration,
  project registration, project-menu, directory-picker, translation, and
  macOS window-behavior fixes.
- **Validated:** Package install check, CLI version, Desktop launcher and icon,
  `opencode/deepseek-v4-flash-free` model discovery, complete NixOS build, and
  closure comparison limited to OpenCode and the dependent update checker.
- **State:** Built only; activation and interactive CLI/Desktop tests remain
  pending.

### 2026-08-10 — Update T3 Code to 0.0.33

- **Changed:** Replace the pinned T3 Code 0.0.24 AppImage with stable 0.0.33,
  retain the declarative Codex, Claude/Albion, and Cursor compatibility
  launchers, and follow upstream's icon move from 1024px to 512px.
- **Reason:** Receive the current Sidebar v2, project/worktree controls,
  pasted-image support, usage improvements, and provider/server reliability
  fixes from the latest stable release.
- **Validated:** GitHub release metadata and published asset digest, fetched
  AppImage build, packaged 0.0.33 metadata, launcher smoke check, complete NixOS
  build, and closure comparison showing only T3 Code changed.
- **State:** Built only; activation and in-app provider tests remain pending.

### 2026-08-10 — Refresh the Codex Desktop Linux integration

- **Changed:** Advance the pinned `codex-desktop-linux` input from
  `d48fa56a` to `d00ee708`, retaining OpenAI Codex Desktop `26.803.41515` while
  adding the current Linux watcher, Computer Use, plugin, performance,
  conversation-deletion, and security-related integration fixes.
- **Reason:** Bring the Linux compatibility layer up to date even though the
  underlying OpenAI application release is already current.
- **Validated:** Named-input lock update, complete NixOS build from fetched
  sources, and closure comparison showing only `codex-desktop` changed.
- **State:** Activated; the new launcher correctly detected and rejected an
  older still-running Codex process, which must be closed before the refreshed
  app can start.

### 2026-08-09 — Extract checker to a standalone private flake; consume it as a pinned input

- **Changed:** The checker source/tests/package moved out of this repository
  into the standalone **private** flake
  `github:AmbitiousRealism2025/coding-tool-update-check`
  (extracted to `/home/ambitiousrealism/coding-projects/coding-tool-update-check`,
  README + MIT license + `.gitignore` excluding reports/state). This flake now
  consumes it as a pinned `flake.lock` input
  (`coding-tools-update-check.url = "github:AmbitiousRealism2025/coding-tool-update-check"`),
  exposes it as `packages.x86_64-linux.codingToolsUpdateCheck` (built through
  the input's overlay with this repository's pinned OpenCode CLI), and runs
  its test suite as `checks.x86_64-linux.coding-tools-update-check`. The
  vendored `pkgs/coding-tools-update-check*` files were removed.
- **Standalone flake outputs:** `packages.<system>.default` (+ `checker`
  alias), `checks.<system>.default` (unittest suite, sandboxed),
  `formatter.<system>` (nixfmt), `overlays.default` for consumers to override
  `opencodeCli`.
- **Reports:** canonical reports stay at
  `~/.local/state/coding-tool-update-check/` (`latest.md`/`latest.json`,
  `reports/report-<stamp>.{md,json}`, `state.json`, `check.lock`); the coding
  project's `reports/` entry is now a symlink to the state `reports/` directory
  and is never Git-tracked.
- **Token estimates:** reports now include approximate prompt/output/total
  token estimates (~4 chars/token heuristic, labelled ±20%; the OpenCode event
  stream does not expose tokenizer usage).
- **Bounded retry:** a malformed (non-JSON-object) or empty model response
  triggers exactly one retry with the identical prompt; timeouts/non-zero
  exits are never retried. Attempt counts are recorded in reports.
- **Home Manager:** `services.codingToolsUpdateCheck` gains a configurable
  `onCalendar` option (default `"daily"`); `RandomizedDelaySec` (default 6h)
  and `Persistent = true` are retained, as are `summarize`, `notify`,
  `notifyOnSuccess`, and `repoRoot`.
- **Validated:** 60 unit tests (previous 54 plus token-estimate and bounded
  retry tests) via `nix flake check` on the standalone flake, standalone
  package build + install check + live `--dry-run`, `nix flake check` on this
  repository, `nix build` of the checker package from the input, and an
  offline recovery run with a throwaway state directory. The private
  repository was created only after a secret scan of every committed file;
  this repository was not staged or pushed. No activation performed
  (`sudo`/`nixos-rebuild` pending user review).

### 2026-08-09 — Add the declarative coding-tool update checker

- **Changed:** Added the checker (pure-Python, stdlib-only; initially vendored
  under `pkgs/coding-tools-update-check`, later extracted to the standalone
  private flake — see the next ledger entry) and wired it into the flake
  (`packages`, a flake `check` running its unittest suite, and Home Manager). A persistent daily randomized user timer/service
  (`services.codingToolsUpdateCheck` in `home/ambitiousrealism/update-checker.nix`)
  runs it once per day at a randomized time and catches up after boot
  (`Persistent = true`).
- **Monitored tools (exactly the requested set):** Codex CLI and Codex Desktop,
  T3 Code, Cursor (GUI) and the Cursor Agent CLI, Pi, and Prime Agent.
  OpenCode/Claude/Albion/Claudex are not monitored; OpenCode is only the
  summarization runtime.
- **CLI:** `--force` (bypass duplicate-notification suppression, never
  installs), `--json` (prints this run's JSON report), `--show` (prints
  `latest.md` without a new network check), `--notify-success` (off by
  default), `--no-notify`, `--dry-run`, `--offline`, `--list-tools`, useful
  `--help`.
- **Reports (exact paths):** `~/.local/state/coding-tool-update-check/latest.md`
  and `latest.json` (always current), `reports/report-<stamp>.{md,json}` history
  (microsecond timestamps, collision-safe), `state.json` (notification dedup;
  versions are only marked notified after `notify-send` delivers), `check.lock`
  (single-instance). Atomic writes throughout; retention only touches the
  reports directory.
- **Per-tool status:** exact states "up to date", "update available", "unable
  to determine", "installed newer", plus release date/title/URL, Nix control
  path, source errors, the nixpkgs three-way distinction (upstream newer vs
  pinned nixpkgs already carrying it vs input refresh required), and release
  detail fields (features/fixes/security/performance/breaking/deprecations/
  migration) or explicit "unavailable".
- **Notifications:** one notification listing genuinely newer tools; one
  concise failure notification when every upstream check fails; partial errors
  only recorded in the report; success notifications only with
  `--notify-success`. Home Manager options (`summarize`, `notify`,
  `notifyOnSuccess`) control the real service flags; the unit requests
  network-online ordering where available.
- **Model:** release-note summarization uses the exact runtime OpenCode model
  `opencode/deepseek-v4-flash-free`, verified at runtime with `opencode models`;
  non-exact models are refused (no `--summarize-model` option). A model failure
  is reported clearly while the deterministic report remains valid.
- **Sources:** authoritative upstreams only - GitHub `releases/latest`, the
  pinned `codex-desktop-linux` flake input's own `flake.nix`, and
  Cursor's official update endpoints (`api2.cursor.sh` update manifest,
  `cursor.com/install` lab path), clearly marked informational in the report.
- **Validated:** 54 unit tests (version ordering, tool registry, store-closure
  suffix filtering, flake.lock parsing, per-tool states, nixpkgs distinction,
  model verification/refusal, structured summaries, report paths, collision-safe
  stamps, retention safety, atomic writes, duplicate + `--force` notifications,
  all-fail failure notification, notify-failure not marking, `--show`/`--json`),
  formatter (nixfmt), `nix flake check`, package build, full NixOS toplevel
  build, closure inspection, and a live end-to-end run against the running
  system closure. The checker was never launched on GUI/Electron binaries;
  versions come from `--version` (verified headless) or store-path names only.
- **State:** Built and validated in this repository; defined for Home Manager
  but not activated (no `sudo`/`nixos-rebuild` performed; activation is pending
  user review).

### 2026-08-08 — Add Prime Agent

- **Changed:** Pin Prime Agent 0.7.1 to Prime Intellect's official release
  artifact with Node.js 22, its fixed npm dependency closure, the ZeroMQ native
  module, and a complete Nix-managed Python kernel environment. Disable mutable
  version checks and Prime telemetry by default in the wrapper.
- **Reason:** Make the `prime-agent` CLI and all kernel dependencies available
  globally without relying on its mutable installer or runtime package setup.
- **Validated:** Release and npm hashes, CLI version, Python import checks,
  native-library patching, and a complete NixOS build.
- **State:** Activated from an isolated candidate based on the prior running
  closure; CLI version and kernel environment verified, then user-tested with
  Codex and ZAI provider connections.

### 2026-08-08 — Add the Pi coding agent

- **Changed:** Pin `pi-coding-agent` 0.84.1 directly to the matching
  `earendil-works/pi` release, npm dependency closure, and generated provider
  model catalog. Disable its mutable self-update check and telemetry by
  default in the Nix wrapper.
- **Reason:** Make the Pi interactive coding-agent CLI available globally as
  the `pi` command without relying on a mutable npm installation.
- **Validated:** Independent source/model hashes, fixed npm dependency hash,
  package version check, wrapper inspection, and complete NixOS build.
- **State:** Version 0.84.1 is activated and tested with Codex.

### 2026-08-08 — Add Cursor Agent CLI for T3 Code

- **Changed:** Install the pinned nixpkgs `cursor-cli` package system-wide and
  expose a Nix-managed `agent` compatibility launcher inside T3 Code's AppImage
  environment.
- **Reason:** T3 v0.0.24 searches for the former `agent` command name, while
  the current Cursor package exposes `cursor-agent`.
- **Validated:** Cursor package and complete NixOS builds, version checks for
  both command paths, and inspection of T3's generated FHS filesystem.
- **State:** Activated from an isolated candidate based on the prior running
  closure; Cursor login and the in-app provider test remain pending.

### 2026-08-08 — Restore T3 Claude provider discovery

- **Changed:** Expose the declarative Albion `claude` launcher inside T3 Code's
  AppImage FHS environment while preserving its existing Codex proxy.
- **Reason:** T3 reconstructed its sandbox PATH without Albion, so its Claude
  provider reported that Claude Code was unavailable even though terminal
  launches worked.
- **Validated:** Package and complete NixOS builds plus inspection of the T3
  backend environment and provider discovery behavior.
- **State:** Built only; activation and the in-app Claude provider test remain
  pending.

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
- **State:** Activated from an isolated candidate based on the exact prior
  running closure; warning-free launch confirmed and user-tested.

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
