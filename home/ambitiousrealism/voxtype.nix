{
  lib,
  pkgs,
  voxtype,
  ...
}:

let
  modelDefs = import (voxtype + "/nix/models.nix");
  fetchWhisperModel =
    name:
    let
      definition = modelDefs.${name};
    in
    pkgs.fetchurl {
      inherit (definition) url hash;
      name = "voxtype-${name}.bin";
    };
  fetchParakeetFile =
    {
      repo,
      filename,
      hash,
    }:
    pkgs.fetchurl {
      url = "https://huggingface.co/${repo}/resolve/main/${filename}";
      inherit hash;
      name = "${lib.replaceStrings [ "/" ] [ "-" ] repo}-${filename}";
    };
  mkParakeetModel =
    {
      name,
      repo,
      files,
    }:
    pkgs.linkFarm name (
      map (
        file: {
          name = file.filename;
          path = fetchParakeetFile {
            inherit repo;
            inherit (file) filename hash;
          };
        }
      ) files
    );

  robustModel = fetchWhisperModel "large-v3-turbo";
  baseModel = fetchWhisperModel "base.en";
  smallModel = fetchWhisperModel "small.en";

  # These are the four files Voxtype 0.7.5 identifies for each quantized TDT
  # model.  Each source is pinned by SHA-256 and is placed in a read-only
  # directory, so the profiles do not depend on Voxtype's mutable setup flow.
  parakeetV2Int8Model = mkParakeetModel {
    name = "voxtype-parakeet-tdt-0.6b-v2-int8";
    repo = "istupakov/parakeet-tdt-0.6b-v2-onnx";
    files = [
      {
        filename = "encoder-model.int8.onnx";
        hash = "sha256-PgWB/aarhDiItR5W1+54ttW8MjfsETrx9zLR1ShqoVU=";
      }
      {
        filename = "decoder_joint-model.int8.onnx";
        hash = "sha256-pEn0ms1ol51BhlHdLctzfMDxvwIl4AninuMmNU7b99M=";
      }
      {
        filename = "vocab.txt";
        hash = "sha256-7BgrcN1CETr/bFNyx1ysWMlSRD6yIyL1e71/U5d9SX0=";
      }
      {
        filename = "config.json";
        hash = "sha256-ZmkDx2uXmMrywhCv1PbNYLCKjb+YAOyNejvA0hSKxGY=";
      }
    ];
  };
  parakeetV3Int8Model = mkParakeetModel {
    name = "voxtype-parakeet-tdt-0.6b-v3-int8";
    repo = "istupakov/parakeet-tdt-0.6b-v3-onnx";
    files = [
      {
        filename = "encoder-model.int8.onnx";
        hash = "sha256-YTnS+n4bCGCXsnfHFJcl7bq4nMfHrmSyPHQb5AVa/wk=";
      }
      {
        filename = "decoder_joint-model.int8.onnx";
        hash = "sha256-7qdIPuPRowN12u3I7YPjlgyRsJiBISeg2Z0ciXdmenA=";
      }
      {
        filename = "vocab.txt";
        hash = "sha256-1YVEZ56kvGrFY9H1Ret9R0vWz6Rn8KbiwdwcfTfjw10=";
      }
      {
        filename = "config.json";
        hash = "sha256-ZmkDx2uXmMrywhCv1PbNYLCKjb+YAOyNejvA0hSKxGY=";
      }
    ];
  };

  robustPackage = voxtype.packages.${pkgs.system}.vulkan;
  cpuWhisperPackage = voxtype.packages.${pkgs.system}.default;
  cpuOnnxPackage = voxtype.packages.${pkgs.system}.onnx;
  toml = pkgs.formats.toml { };

  technicalVocabulary = "Technical dictation about NixOS, Hyprland, UWSM, DMS, Omarchy, CachyOS, Voxtype, Codex, Cursor, Kitty, NVIDIA T1200, PRIME RTD3, OnePassword, OpenCode, Traycer, T3 Code, and Zen Browser.";
  technicalReplacements = {
    "nix os" = "NixOS";
    "hypr land" = "Hyprland";
    "u w s m" = "UWSM";
    "d m s" = "DMS";
    "vox type" = "Voxtype";
    "amarchi" = "Omarchy";
    "casio us" = "CachyOS";
    "cashy os" = "CachyOS";
    "t 1200" = "T1200";
    "twelve hundred" = "T1200";
    "one password" = "1Password";
    "open code" = "OpenCode";
    "t three code" = "T3 Code";
  };
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

    text.replacements = technicalReplacements;

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
        initial_prompt = technicalVocabulary;
        gpu_isolation = true;
        flash_attention = true;
        # The full 30-second context took 39 seconds for a 3.5-second phrase on
        # the T1200. Upstream's conservative short-clip context reduced the
        # same local Vulkan diagnostic from 7.9 seconds to 0.83 seconds.
        context_window_optimization = true;
      };
    }
  );

  baseConfig = toml.generate "voxtype-base.toml" (
    lib.recursiveUpdate commonSettings {
      whisper = {
        model = toString baseModel;
        language = "en";
        translate = false;
        initial_prompt = technicalVocabulary;
        gpu_isolation = false;
        context_window_optimization = true;
      };
    }
  );

  smallConfig = toml.generate "voxtype-small.toml" (
    lib.recursiveUpdate commonSettings {
      whisper = {
        model = toString smallModel;
        language = "en";
        translate = false;
        initial_prompt = technicalVocabulary;
        gpu_isolation = false;
        context_window_optimization = true;
      };
    }
  );

  mkParakeetConfig = name: model:
    toml.generate "voxtype-${name}.toml" (
      lib.recursiveUpdate commonSettings {
        engine = "parakeet";
        parakeet = {
          model = toString model;
          model_type = "tdt";
          # Keep each benchmark model warm. The i7-11850H has ample RAM, and
          # this measures transcription rather than model-load latency.
          on_demand_loading = false;
        };
      }
    );
  parakeetV2Config = mkParakeetConfig "parakeet-v2-int8" parakeetV2Int8Model;
  parakeetV3Config = mkParakeetConfig "parakeet-v3-int8" parakeetV3Int8Model;

  voxtypeUnits = [
    "voxtype.service"
    "voxtype-light.service"
    "voxtype-small.service"
    "voxtype-parakeet-v2.service"
    "voxtype-parakeet-v3.service"
  ];
  baseUnit = {
    Documentation = "https://voxtype.io";
    PartOf = [ "graphical-session.target" ];
    After = [
      "graphical-session.target"
      "pipewire.service"
      "pipewire-pulse.service"
    ];
  };
  cpuService = package: config: {
    Type = "simple";
    ExecStart = "${package}/bin/voxtype --config ${config} daemon";
    Restart = "on-failure";
    RestartSec = 5;
  };

  profileCommand = pkgs.writeShellApplication {
    name = "voxtype-profile";
    runtimeInputs = [
      pkgs.systemd
      pkgs.libnotify
    ];
    text = ''
      units=(
        voxtype.service
        voxtype-light.service
        voxtype-small.service
        voxtype-parakeet-v2.service
        voxtype-parakeet-v3.service
      )
      case "''${1:-status}" in
        robust)
          target=voxtype.service
          label='robust (NVIDIA Vulkan, large-v3-turbo)'
          ;;
        light)
          target=voxtype-light.service
          label='light (CPU, base.en)'
          ;;
        small)
          target=voxtype-small.service
          label='small (CPU, Whisper small.en)'
          ;;
        parakeet-v2)
          target=voxtype-parakeet-v2.service
          label='parakeet-v2 (CPU, TDT v2 int8)'
          ;;
        parakeet-v3)
          target=voxtype-parakeet-v3.service
          label='parakeet-v3 (CPU, TDT v3 int8)'
          ;;
        status)
          for unit in "''${units[@]}"; do
            printf '%s %s\n' "$unit" "$(systemctl --user is-active "$unit" 2>/dev/null || true)"
          done
          exit 0
          ;;
        *)
          printf 'usage: voxtype-profile {robust|light|small|parakeet-v2|parakeet-v3|status}\n' >&2
          exit 64
          ;;
      esac

      for unit in "''${units[@]}"; do
        systemctl --user stop "$unit" 2>/dev/null || true
      done
      systemctl --user restart "$target"
      notify-send 'Voxtype profile' "$label"
    '';
  };
in
{
  # Only the robust package owns the unqualified `voxtype` command. The CPU
  # services use immutable store paths, preventing command collisions.
  home.packages = [
    robustPackage
    profileCommand
  ];

  xdg.configFile = {
    "voxtype/profiles/robust.toml".source = robustConfig;
    "voxtype/profiles/base.toml".source = baseConfig;
    "voxtype/profiles/small.toml".source = smallConfig;
    "voxtype/profiles/parakeet-v2-int8.toml".source = parakeetV2Config;
    "voxtype/profiles/parakeet-v3-int8.toml".source = parakeetV3Config;
  };

  systemd.user.services = {
    voxtype = {
      Unit = baseUnit // {
        Description = "Voxtype robust NVIDIA Vulkan profile";
        Conflicts = lib.remove "voxtype.service" voxtypeUnits;
      };
      Service = (cpuService robustPackage robustConfig) // {
        Environment = [
          "VOXTYPE_VULKAN_DEVICE=nvidia"
          "__NV_PRIME_RENDER_OFFLOAD=1"
          "__VK_LAYER_NV_optimus=NVIDIA_only"
          "__GLX_VENDOR_LIBRARY_NAME=nvidia"
        ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    voxtype-light = {
      Unit = baseUnit // {
        Description = "Voxtype light CPU Whisper profile";
        Conflicts = lib.remove "voxtype-light.service" voxtypeUnits;
      };
      Service = cpuService cpuWhisperPackage baseConfig;
    };

    voxtype-small = {
      Unit = baseUnit // {
        Description = "Voxtype CPU Whisper small.en profile";
        Conflicts = lib.remove "voxtype-small.service" voxtypeUnits;
      };
      Service = cpuService cpuWhisperPackage smallConfig;
    };

    voxtype-parakeet-v2 = {
      Unit = baseUnit // {
        Description = "Voxtype CPU Parakeet TDT v2 int8 profile";
        Conflicts = lib.remove "voxtype-parakeet-v2.service" voxtypeUnits;
      };
      Service = cpuService cpuOnnxPackage parakeetV2Config;
    };

    voxtype-parakeet-v3 = {
      Unit = baseUnit // {
        Description = "Voxtype CPU Parakeet TDT v3 int8 profile";
        Conflicts = lib.remove "voxtype-parakeet-v3.service" voxtypeUnits;
      };
      Service = cpuService cpuOnnxPackage parakeetV3Config;
    };
  };
}
