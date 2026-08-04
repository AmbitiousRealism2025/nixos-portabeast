{
  lib,
  pkgs,
  voxtype,
  ...
}:

let
  modelDefs = import (voxtype + "/nix/models.nix");
  fetchModel =
    name:
    let
      definition = modelDefs.${name};
    in
    pkgs.fetchurl {
      inherit (definition) url hash;
      name = "voxtype-${name}.bin";
    };

  robustModel = fetchModel "large-v3-turbo";
  lightModel = fetchModel "base.en";
  robustPackage = voxtype.packages.${pkgs.system}.vulkan;
  lightPackage = voxtype.packages.${pkgs.system}.default;
  toml = pkgs.formats.toml { };

  commonSettings = {
    engine = "whisper";
    state_file = "auto";

    # Hyprland owns the bare Insert binding. Avoid evdev access and the input
    # group entirely; the CLI talks to the already-running user daemon.
    hotkey.enabled = false;

    audio = {
      device = "default";
      sample_rate = 16000;
      max_duration_secs = 60;
    };

    # DMS notifications provide the status feedback, so a second OSD layer is
    # unnecessary and avoids the upstream Quickshell pointer-capture issue.
    osd.enabled = false;

    output = {
      mode = "type";
      fallback_to_clipboard = true;
      driver_order = [
        "wtype"
        "clipboard"
      ];
      type_delay_ms = 0;
      pre_type_delay_ms = 0;
      notification = {
        on_recording_start = true;
        on_recording_stop = true;
        on_transcription = true;
      };
    };
  };

  robustConfig = toml.generate "voxtype-robust.toml" (
    lib.recursiveUpdate commonSettings {
      whisper = {
        model = toString robustModel;
        language = "en";
        translate = false;
        gpu_isolation = true;
        flash_attention = true;
        # The full 30-second context took 39 seconds for a 3.5-second phrase on
        # the T1200. Upstream's conservative short-clip context reduced the
        # same local Vulkan diagnostic from 7.9 seconds to 0.83 seconds.
        context_window_optimization = true;
      };
    }
  );

  lightConfig = toml.generate "voxtype-light.toml" (
    lib.recursiveUpdate commonSettings {
      whisper = {
        model = toString lightModel;
        language = "en";
        translate = false;
        gpu_isolation = false;
        context_window_optimization = true;
      };
    }
  );

  profileCommand = pkgs.writeShellApplication {
    name = "voxtype-profile";
    runtimeInputs = [
      pkgs.systemd
      pkgs.libnotify
    ];
    text = ''
      case "''${1:-status}" in
        robust)
          systemctl --user stop voxtype-light.service
          systemctl --user restart voxtype.service
          notify-send "Voxtype profile" "robust (NVIDIA Vulkan, large-v3-turbo)"
          ;;
        light)
          systemctl --user stop voxtype.service
          systemctl --user restart voxtype-light.service
          notify-send "Voxtype profile" "light (portable CPU, base.en)"
          ;;
        status)
          robust_state="$(systemctl --user is-active voxtype.service 2>/dev/null || true)"
          light_state="$(systemctl --user is-active voxtype-light.service 2>/dev/null || true)"
          if [ "$robust_state" = active ] && [ "$light_state" != active ]; then
            printf 'robust active; light %s\n' "$light_state"
          elif [ "$light_state" = active ] && [ "$robust_state" != active ]; then
            printf 'light active (portable CPU); robust %s\n' "$robust_state"
          else
            printf 'invalid profile state: robust=%s light=%s\n' "$robust_state" "$light_state" >&2
            exit 1
          fi
          ;;
        *)
          printf 'usage: voxtype-profile {robust|light|status}\n' >&2
          exit 64
          ;;
      esac
    '';
  };
in
{
  # Only the robust package owns the unqualified `voxtype` command. The light
  # service uses its immutable store path, preventing command collisions.
  home.packages = [
    robustPackage
    profileCommand
  ];

  xdg.configFile."voxtype/profiles/robust.toml".source = robustConfig;
  xdg.configFile."voxtype/profiles/light.toml".source = lightConfig;

  systemd.user.services = {
    voxtype = {
      Unit = {
        Description = "Voxtype robust NVIDIA Vulkan profile";
        Documentation = "https://voxtype.io";
        PartOf = [ "graphical-session.target" ];
        After = [
          "graphical-session.target"
          "pipewire.service"
          "pipewire-pulse.service"
        ];
        Conflicts = [ "voxtype-light.service" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${robustPackage}/bin/voxtype --config ${robustConfig} daemon";
        Environment = [
          "VOXTYPE_VULKAN_DEVICE=nvidia"
          "__NV_PRIME_RENDER_OFFLOAD=1"
          "__VK_LAYER_NV_optimus=NVIDIA_only"
          "__GLX_VENDOR_LIBRARY_NAME=nvidia"
        ];
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    voxtype-light = {
      Unit = {
        Description = "Voxtype light portable CPU profile";
        Documentation = "https://voxtype.io";
        PartOf = [ "graphical-session.target" ];
        After = [
          "graphical-session.target"
          "pipewire.service"
          "pipewire-pulse.service"
        ];
        Conflicts = [ "voxtype.service" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${lightPackage}/bin/voxtype --config ${lightConfig} daemon";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
