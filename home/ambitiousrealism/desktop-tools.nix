{ pkgs, ... }:

{
  # Cursor is the selected graphical/terminal editor. Kate remains installed
  # by NixOS as a Plasma-safe fallback.
  home.packages = with pkgs; [
    code-cursor
    thunderbird
    discord

    # General terminal, inspection, transfer, and development tools selected
    # together as the first low-risk utility batch.
    btop
    duf
    fastfetch
    ripgrep
    rsync
    less
    unrar
    python3
    nodejs
    cmake

    # Graphical diff/merge tool. DMS receives its executable separately below.
    meld
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
