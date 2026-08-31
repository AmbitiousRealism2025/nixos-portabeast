{ pkgs, ... }:

let
  zenBrowser = pkgs.callPackage ./pkgs/zen-browser.nix { };
in
{
  # Zen is the selected browser. Firefox remains installed through its NixOS
  # module as an independently packaged recovery browser. Google Chrome is
  # available specifically for WebHID applications such as Keychron Launcher.
  environment.systemPackages = [
    zenBrowser
    pkgs.google-chrome
  ];

  # Grant only the active local session access to Keychron's raw HID devices.
  # Chrome needs this ACL to connect through WebHID without running as root.
  services.udev.extraRules = ''
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="3434", TAG+="uaccess"
  '';
}
