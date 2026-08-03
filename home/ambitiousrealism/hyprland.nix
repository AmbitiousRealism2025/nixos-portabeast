{ lib, pkgs, ... }:

let
  lua = lib.generators.mkLuaInline;

  mkExecBind = key: command: {
    _args = [
      key
      (lua "hl.dsp.exec_cmd(${builtins.toJSON command})")
    ];
  };

  mkHyprctlBind =
    key: dispatcher: argument:
    mkExecBind key (
      lib.concatStringsSep " " (
        [
          "hyprctl"
          "dispatch"
          dispatcher
        ]
        ++ lib.optional (argument != "") argument
      )
    );

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
  # Fuzzel is a temporary lightweight launcher until DMS Spotlight is added
  # and tested in its own generation.
  home.packages = with pkgs; [
    brightnessctl
    fuzzel
  ];
  home.sessionVariables.TERMINAL = "konsole";

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
        # Applications: keep the proven Plasma applications in this minimal
        # session. Kitty and DMS replace these temporary choices later.
        (mkExecBind "SUPER + RETURN" "uwsm app -- /run/current-system/sw/bin/konsole")
        (mkExecBind "SUPER + SHIFT + RETURN" "uwsm app -- /run/current-system/sw/bin/firefox")
        (mkExecBind "SUPER + SPACE" "uwsm app -- ${pkgs.fuzzel}/bin/fuzzel")

        # Omarchy-compatible tiling and focus muscle memory.
        (mkNativeBind "SUPER + W" "hl.dsp.window.close()")
        (mkNativeBind "SUPER + T" ''hl.dsp.window.float({ action = "toggle" })'')
        (mkNativeBind "SUPER + J" ''hl.dsp.layout("togglesplit")'')
        (mkNativeBind "SUPER + P" "hl.dsp.window.pseudo()")
        (mkHyprctlBind "SUPER + F" "fullscreen" "0")
        (mkHyprctlBind "SUPER + ALT + F" "fullscreen" "1")
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
        (mkHyprctlBind "ALT + TAB" "cyclenext" "")
        (mkHyprctlBind "ALT + SHIFT + TAB" "cyclenext" "prev")
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
