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

  screenshotRegion = pkgs.writeShellApplication {
    name = "screenshot-region";
    runtimeInputs = with pkgs; [
      coreutils
      grim
      slurp
      wl-clipboard
      libnotify
      xdg-user-dirs
    ];
    text = ''
      region="$(slurp)" || exit 0
      [ -n "$region" ] || exit 0

      pictures="$(xdg-user-dir PICTURES)"
      output_dir="$pictures/Screenshots"
      mkdir -p "$output_dir"
      output="$output_dir/$(date +%Y-%m-%d_%H-%M-%S).png"

      grim -g "$region" "$output"
      wl-copy < "$output"
      notify-send "Screenshot saved" "$output"
    '';
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
    screenshotRegion
  ];
  home.sessionVariables.TERMINAL = "kitty";

  programs.kitty = {
    enable = true;
    keybindings = {
      "alt+shift+c" = "copy_to_clipboard";
      "alt+shift+v" = "paste_from_clipboard";
    };
    settings = {
      confirm_os_window_close = 0;

      # Graphene terminal palette: quiet near-black surfaces with the
      # wallpaper's cyan, electric-blue, indigo, and charcoal-violet accents.
      background = "#000000";
      foreground = "#dffcff";
      selection_background = "#333399";
      selection_foreground = "#ffffff";
      cursor = "#66cccc";
      cursor_text_color = "#000000";
      url_color = "#66cccc";
      active_border_color = "#66cccc";
      inactive_border_color = "#424153";
      active_tab_background = "#0066cc";
      active_tab_foreground = "#ffffff";
      inactive_tab_background = "#11142a";
      inactive_tab_foreground = "#a9cbd2";

      color0 = "#000000";
      color1 = "#ef708f";
      color2 = "#66cccc";
      color3 = "#e6b96c";
      color4 = "#0066cc";
      color5 = "#8b8be6";
      color6 = "#66cccc";
      color7 = "#dffcff";
      color8 = "#424153";
      color9 = "#ff8eaa";
      color10 = "#8ee6e6";
      color11 = "#f4cf8d";
      color12 = "#4b91ff";
      color13 = "#adadff";
      color14 = "#9af2f2";
      color15 = "#ffffff";
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
          gaps_in = 4;
          gaps_out = 4;
          border_size = 2;
          layout = "dwindle";
          "col.active_border" = "rgba(66ccccff)";
          "col.inactive_border" = "rgba(424153cc)";
          "col.nogroup_border_active" = "rgba(0066ccff)";
          "col.nogroup_border" = "rgba(333399aa)";
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
          shadow = {
            enabled = true;
            range = 8;
            render_power = 2;
            color = "rgba(0066cc44)";
            color_inactive = "rgba(00000055)";
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
        # Applications: Kitty and the selected Zen browser use direct bindings. DMS
        # Spotlight becomes the primary launcher, with Fuzzel one chord away
        # as a shell-independent recovery fallback.
        (mkExecBind "SUPER + RETURN" "uwsm app -- ${pkgs.kitty}/bin/kitty")
        (mkExecBind "SUPER + SHIFT + RETURN" "uwsm app -- /run/current-system/sw/bin/zen")
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

        # Omarchy's region-capture workflow: save under XDG Pictures, copy the
        # PNG to the clipboard, and show the final path in a notification.
        (mkExecBind "PRINT" "${screenshotRegion}/bin/screenshot-region")

        # Apple-shaped editing muscle memory. Hyprland translates these
        # focused-window shortcuts natively, while physical Ctrl+C remains
        # available for terminal interrupts. Kitty owns its shifted copy and
        # paste variants above so they never collide with shell control keys.
        (mkNativeBind "ALT + C" ''hl.dsp.send_shortcut({ mods = "CTRL", key = "C" })'')
        (mkNativeBind "ALT + V" ''hl.dsp.send_shortcut({ mods = "CTRL", key = "V" })'')
        (mkNativeBind "ALT + X" ''hl.dsp.send_shortcut({ mods = "CTRL", key = "X" })'')
        (mkNativeBind "ALT + Z" ''hl.dsp.send_shortcut({ mods = "CTRL", key = "Z" })'')

        # Omarchy-compatible tiling and focus muscle memory.
        (mkNativeBind "SUPER + Q" "hl.dsp.window.close()")
        (mkNativeBind "SUPER + T" ''hl.dsp.window.float({ action = "toggle" })'')
        (mkNativeBind "SUPER + P" "hl.dsp.window.pseudo()")
        (mkNativeBind "SUPER + W" ''
          hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" })
        '')
        (mkNativeBind "SUPER + F" ''
          hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })
        '')
        (mkNativeBind "SUPER + H" ''hl.dsp.focus({ direction = "left" })'')
        (mkNativeBind "SUPER + J" ''hl.dsp.focus({ direction = "up" })'')
        (mkNativeBind "SUPER + K" ''hl.dsp.focus({ direction = "down" })'')
        (mkNativeBind "SUPER + L" ''hl.dsp.focus({ direction = "right" })'')
        (mkNativeBind "SUPER + SHIFT + H" ''hl.dsp.window.move({ direction = "left" })'')
        (mkNativeBind "SUPER + SHIFT + J" ''hl.dsp.window.move({ direction = "up" })'')
        (mkNativeBind "SUPER + SHIFT + K" ''hl.dsp.window.move({ direction = "down" })'')
        (mkNativeBind "SUPER + SHIFT + L" ''hl.dsp.window.move({ direction = "right" })'')
        (mkNativeBind "SUPER + TAB" ''hl.dsp.focus({ workspace = "e+1" })'')
        (mkNativeBind "SUPER + SHIFT + TAB" ''hl.dsp.focus({ workspace = "e-1" })'')
        (mkNativeBind "ALT + TAB" "hl.dsp.window.cycle_next({ next = true })")
        (mkNativeBind "ALT + SHIFT + TAB" "hl.dsp.window.cycle_next({ next = false })")
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
