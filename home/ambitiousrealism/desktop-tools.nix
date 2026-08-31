{ cursorGui, pkgs, ... }:

{
  # Cursor is the selected graphical/terminal editor. Kate remains installed
  # by NixOS as a Plasma-safe fallback.
  home.packages = [ cursorGui ] ++ (with pkgs; [
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
  ]);

  home.sessionVariables = {
    EDITOR = "cursor --wait";
    VISUAL = "cursor --wait";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
  };

  programs.git.settings.core.editor = "cursor --wait";

  # Keep Deep Sage as a selectable rollback and package Graphene as the
  # wallpaper-matched dark theme selected by the reviewed preview script.
  xdg.configFile."DankMaterialShell/themes/deepsage/theme.json".source = ./deepsage-theme.json;
  xdg.configFile."DankMaterialShell/themes/graphene/theme.json".source = ./graphene-theme.json;

  # Store the selected 16:10 crop declaratively so DMS never depends on the
  # disposable Downloads copy of the wallpaper.
  home.file."Pictures/Wallpapers/graphene.png".source = ./graphene-wallpaper.png;
}
