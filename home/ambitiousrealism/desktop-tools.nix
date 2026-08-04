{ pkgs, ... }:

{
  # Cursor is the selected graphical/terminal editor. Kate remains installed
  # by NixOS as a Plasma-safe fallback.
  home.packages = with pkgs; [
    code-cursor
    inter
    fira-code
    nerd-fonts.jetbrains-mono
  ];

  home.sessionVariables = {
    EDITOR = "cursor --wait";
    VISUAL = "cursor --wait";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };

  programs.git.settings.core.editor = "cursor --wait";

  # Package the reviewed Deep Sage artifact, but let DMS 1.4.6 select it
  # through its own schema-aware settings UI during the visual test.
  xdg.configFile."DankMaterialShell/themes/deepsage/theme.json".source = ./deepsage-theme.json;
}
