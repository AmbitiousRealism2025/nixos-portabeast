{ config, nemoPreview, pkgs, ... }:

{
  # Trial both file-manager styles without changing any existing MIME or
  # directory defaults.
  home.packages = [
    pkgs.nemo
    nemoPreview
  ];

  programs.yazi = {
    enable = true;
    enableZshIntegration = true;

    # Nixpkgs already wraps Yazi with its preview, archive, search, and
    # navigation helpers. Add native Wayland clipboard integration here.
    extraPackages = [ pkgs.wl-clipboard ];
  };

  # Nemo's upstream launcher is generically named "Files". Explicit entries
  # make both candidates unambiguous in DMS Spotlight and ensure Yazi always
  # opens inside the configured Kitty terminal.
  xdg.desktopEntries.nemo = {
    name = "Nemo";
    genericName = "File Manager";
    comment = "Browse and organize files with Nemo";
    exec = "${pkgs.nemo}/bin/nemo %U";
    icon = "nemo";
    terminal = false;
    categories = [ "System" "FileManager" ];
  };

  xdg.desktopEntries.yazi = {
    name = "Yazi";
    genericName = "Terminal File Manager";
    comment = "Browse and organize files in Kitty with Yazi";
    exec = "${pkgs.kitty}/bin/kitty --class yazi -e ${config.programs.yazi.finalPackage}/bin/yazi";
    icon = "yazi";
    terminal = false;
    categories = [ "System" "FileManager" ];
  };
}
