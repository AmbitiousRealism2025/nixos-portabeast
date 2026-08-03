{ pkgs, ... }:

{
  imports = [ ./shell.nix ];

  home = {
    username = "ambitiousrealism";
    homeDirectory = "/home/ambitiousrealism";
    stateVersion = "26.05";
  };

  # Keep Plasma's existing ~/.config/user-dirs.dirs authoritative.
  xdg.enable = true;

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    glances
    glow
    unzip
    p7zip
  ];
}
