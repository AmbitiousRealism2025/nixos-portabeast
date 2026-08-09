{
  config,
  codingToolsUpdateCheck,
  lib,
  ...
}:

# Persistent daily coding-tool update check as a user-level systemd service.
#
# The checker itself is the standalone private flake
# github:AmbitiousRealism2025/coding-tool-update-check (pinned in flake.lock);
# this module only wires its timer/service.
#
# The timer fires on ``onCalendar`` (default: daily) at a randomized time
# (RandomizedDelaySec) and Persistent = true makes systemd run the service
# shortly after the user session starts if the machine was off at the
# scheduled time.  The service runs the checker with the exact runtime
# OpenCode model opencode/deepseek-v4-flash-free for release-note
# summarization (the model is verified at runtime with ``opencode models``
# and never substituted), inheriting the user HOME session (never reading
# credential stores).
#
# Every option below is wired into the actual ExecStart flags:
#   * summarize        -> --summarize / --no-summarize
#   * notify           -> --notify / --no-notify
#   * notifyOnSuccess  -> --notify-success (default off)
#
# Reports land at the exact paths:
#   ~/.local/state/coding-tool-update-check/latest.md
#   ~/.local/state/coding-tool-update-check/latest.json
#   ~/.local/state/coding-tool-update-check/reports/

let
  cfg = config.services.codingToolsUpdateCheck;
in
{
  options.services.codingToolsUpdateCheck = {
    enable = lib.mkEnableOption "the daily coding-tool update check";

    repoRoot = lib.mkOption {
      type = lib.types.str;
      default = "/home/ambitiousrealism/nixos-codex-desktop";
      description = "NixOS repository root the checker inspects.";
    };

    summarize = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Summarize release notes with opencode/deepseek-v4-flash-free when updates exist.";
    };

    notify = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Send desktop notifications for updates, all-upstream failures and (when enabled) success.";
    };

    notifyOnSuccess = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Also send a desktop notification when every monitored tool is current (default: false).";
    };

    randomizedDelaySec = lib.mkOption {
      type = lib.types.str;
      default = "6h";
      description = "Randomized delay within the daily window.";
    };

    onCalendar = lib.mkOption {
      type = lib.types.str;
      default = "daily";
      description = "systemd OnCalendar schedule for the check (default: daily).";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ codingToolsUpdateCheck ];

    systemd.user.services.coding-tools-update-check = {
      Unit = {
        Description = "Daily coding-tool update check (standalone checker flake)";
        Documentation = [
          "https://github.com/AmbitiousRealism2025/coding-tool-update-check"
          "https://github.com/AmbitiousRealism2025/nixos-codex-desktop"
        ];
        # Best-effort network ordering: network-online.target normally only
        # exists in the system manager, so in the user manager this is a
        # harmless no-op; the checker independently tolerates an unavailable
        # network through per-request timeouts and per-tool failure isolation.
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart =
          "${codingToolsUpdateCheck}/bin/coding-tools-update-check --repo-root ${cfg.repoRoot} "
          + (if cfg.summarize then "--summarize" else "--no-summarize")
          + " "
          + (if cfg.notify then "--notify" else "--no-notify")
          + (if cfg.notifyOnSuccess then " --notify-success" else "");
        Nice = 10;
        IOSchedulingClass = "idle";
      };
    };

    systemd.user.timers.coding-tools-update-check = {
      Unit = {
        Description = "Daily randomized timer for the coding-tool update check";
      };
      Timer = {
        OnCalendar = cfg.onCalendar;
        RandomizedDelaySec = cfg.randomizedDelaySec;
        Persistent = true;
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };
}
