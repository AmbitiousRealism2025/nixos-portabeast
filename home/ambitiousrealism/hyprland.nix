{ lib, pkgs, ... }:

let
  lua = lib.generators.mkLuaInline;

  mkExecBind = key: command: {
    _args = [
      key
      (lua "hl.dsp.exec_cmd(${builtins.toJSON command})")
    ];
  };

  mkNativeBind = key: action: {
    _args = [
      key
      (lua action)
    ];
  };

  workspaceBinds = lib.concatMap (
    number:
    let
      workspace = toString number;
    in
    [
      (mkNativeBind "SUPER + ${workspace}" ''
        hl.dsp.focus({ workspace = "${workspace}" })
      '')
      (mkNativeBind "SUPER + SHIFT + ${workspace}" ''
        hl.dsp.window.move({ workspace = "${workspace}", follow = false })
      '')
    ]
  ) (lib.range 1 9);
in
{
  # Fuzzel remains a lightweight recovery launcher while DMS is being tested.
  home.packages = with pkgs; [
    brightnessctl
    fuzzel
  ];
  home.sessionVariables.TERMINAL = "kitty";

  programs.kitty = {
    enable = true;
    settings = {
      confirm_os_window_close = 0;
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;

    # NixOS owns Hyprland and its portal. Home Manager owns only the rendered
    # Lua configuration, and UWSM owns the session/systemd lifecycle.
    package = null;
    portalPackage = null;
    configType = "lua";
    systemd.enable = false;

    settings = {
      config = {
        general = {
          gaps_in = 12;
          gaps_out = 12;
          border_size = 4;
          layout = "dwindle";
        };
        decoration = {
          rounding = 10;
          active_opacity = 1.0;
          inactive_opacity = 0.95;
          blur = {
            enabled = true;
            size = 4;
            passes = 2;
          };
        };
        animations.enabled = true;
        input = {
          kb_layout = "us";
          follow_mouse = 1;
        };
        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
        };
      };

      bind = [
        # Applications: Kitty and Firefox retain their proven bindings. DMS
        # Spotlight becomes the primary launcher, with Fuzzel one chord away
        # as a shell-independent recovery fallback.
        (mkExecBind "SUPER + RETURN" "uwsm app -- ${pkgs.kitty}/bin/kitty")
        (mkExecBind "SUPER + SHIFT + RETURN" "uwsm app -- /run/current-system/sw/bin/firefox")
        (mkExecBind "SUPER + SPACE" "${pkgs.dms-shell}/bin/dms ipc call spotlight toggle")
        (mkExecBind "SUPER + SHIFT + SPACE" "uwsm app -- ${pkgs.fuzzel}/bin/fuzzel")

        # Voxtype owns no global input device. Hyprland invokes its local daemon
        # through the ordinary client command when bare Insert is pressed.
        (mkExecBind "INSERT" "voxtype record toggle")

        # Omarchy-shaped shell controls, translated to DMS 1.4.6 IPC methods
        # verified from the package in the pinned NixOS release.
        (mkExecBind "SUPER + ALT + SPACE" "${pkgs.dms-shell}/bin/dms ipc call settings focusOrToggle")
        (mkExecBind "SUPER + ESCAPE" "${pkgs.dms-shell}/bin/dms ipc call powermenu toggle")
        (mkExecBind "SUPER + CTRL + L" "${pkgs.dms-shell}/bin/dms ipc call lock lock")
        (mkExecBind "SUPER + CTRL + V" "${pkgs.dms-shell}/bin/dms ipc call clipboard toggle")
        (mkExecBind "SUPER + CTRL + SPACE" "${pkgs.dms-shell}/bin/dms ipc call dankdash wallpaper")

        # Omarchy-compatible tiling and focus muscle memory.
        (mkNativeBind "SUPER + W" "hl.dsp.window.close()")
        (mkNativeBind "SUPER + T" ''hl.dsp.window.float({ action = "toggle" })'')
        (mkNativeBind "SUPER + J" ''hl.dsp.layout("togglesplit")'')
        (mkNativeBind "SUPER + P" "hl.dsp.window.pseudo()")
        (mkNativeBind "SUPER + F" ''
          hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" })
        '')
        (mkNativeBind "SUPER + ALT + F" ''
          hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })
        '')
        (mkNativeBind "SUPER + LEFT" ''hl.dsp.focus({ direction = "left" })'')
        (mkNativeBind "SUPER + RIGHT" ''hl.dsp.focus({ direction = "right" })'')
        (mkNativeBind "SUPER + UP" ''hl.dsp.focus({ direction = "up" })'')
        (mkNativeBind "SUPER + DOWN" ''hl.dsp.focus({ direction = "down" })'')
        (mkNativeBind "SUPER + SHIFT + LEFT" ''hl.dsp.window.move({ direction = "left" })'')
        (mkNativeBind "SUPER + SHIFT + RIGHT" ''hl.dsp.window.move({ direction = "right" })'')
        (mkNativeBind "SUPER + SHIFT + UP" ''hl.dsp.window.move({ direction = "up" })'')
        (mkNativeBind "SUPER + SHIFT + DOWN" ''hl.dsp.window.move({ direction = "down" })'')
        (mkNativeBind "SUPER + TAB" ''hl.dsp.focus({ workspace = "e+1" })'')
        (mkNativeBind "SUPER + SHIFT + TAB" ''hl.dsp.focus({ workspace = "e-1" })'')
        (mkNativeBind "ALT + TAB" ''hl.dsp.window.cycle_next({ next = true })'')
        (mkNativeBind "ALT + SHIFT + TAB" ''hl.dsp.window.cycle_next({ next = false })'')
        (mkNativeBind "SUPER + mouse_down" ''hl.dsp.focus({ workspace = "e+1" })'')
        (mkNativeBind "SUPER + mouse_up" ''hl.dsp.focus({ workspace = "e-1" })'')

        # DMS will later become the control owner. Until then, retain working
        # audio and brightness hardware keys with the existing PipeWire stack.
        {
          _args = [
            "XF86AudioRaiseVolume"
            (lua ''hl.dsp.exec_cmd("/run/current-system/sw/bin/wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+")'')
            {
              locked = true;
              repeating = true;
            }
          ];
        }
        {
          _args = [
            "XF86AudioLowerVolume"
            (lua ''hl.dsp.exec_cmd("/run/current-system/sw/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")'')
            {
              locked = true;
              repeating = true;
            }
          ];
        }
        {
          _args = [
            "XF86AudioMute"
            (lua ''hl.dsp.exec_cmd("/run/current-system/sw/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")'')
            { locked = true; }
          ];
        }
        {
          _args = [
            "XF86AudioMicMute"
            (lua ''hl.dsp.exec_cmd("/run/current-system/sw/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")'')
            { locked = true; }
          ];
        }
        {
          _args = [
            "XF86MonBrightnessUp"
            (lua ''hl.dsp.exec_cmd("${pkgs.brightnessctl}/bin/brightnessctl -e4 -n2 set 5%+")'')
            {
              locked = true;
              repeating = true;
            }
          ];
        }
        {
          _args = [
            "XF86MonBrightnessDown"
            (lua ''hl.dsp.exec_cmd("${pkgs.brightnessctl}/bin/brightnessctl -e4 -n2 set 5%-")'')
            {
              locked = true;
              repeating = true;
            }
          ];
        }

        # Native mouse actions must remain attached to the button press.
        {
          _args = [
            "SUPER + mouse:272"
            (lua "hl.dsp.window.drag()")
            { mouse = true; }
          ];
        }
        {
          _args = [
            "SUPER + mouse:273"
            (lua "hl.dsp.window.resize()")
            { mouse = true; }
          ];
        }
      ]
      ++ workspaceBinds;
    };
  };
}
