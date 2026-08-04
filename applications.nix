{ pkgs, ... }:

{
  # First application acceptance slice: native, account-free tools whose
  # workflows can be tested without importing state or changing MIME owners.
  environment.systemPackages = with pkgs; [
    # Terminal system inspection.
    btop
    fastfetch
    duf

    # Audio, comparison, image, and video tools.
    pavucontrol
    meld
    imv
    celluloid
    vlc
  ];
}
