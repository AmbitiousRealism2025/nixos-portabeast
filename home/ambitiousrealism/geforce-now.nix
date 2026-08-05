{ pkgs, ... }:

{
  # Shadow the mutable Flatpak export with a stable Home Manager launcher so
  # DMS Spotlight can always resolve the NixOS-owned Flatpak executable. The
  # app itself remains the official user-scoped NVIDIA Flatpak.
  xdg.desktopEntries."com.nvidia.geforcenow" = {
    name = "NVIDIA GeForce NOW";
    genericName = "Cloud Gaming";
    comment = "Stream games with NVIDIA GeForce NOW";
    exec = "${pkgs.flatpak}/bin/flatpak run com.nvidia.geforcenow";
    icon = "com.nvidia.geforcenow";
    terminal = false;
    categories = [
      "Game"
      "Network"
    ];
  };
}
