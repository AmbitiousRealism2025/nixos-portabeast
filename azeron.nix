{ azeronSoftware, pkgs, ... }:

let
  # NixOS generates /etc/udev/rules.d from packages. Copy Azeron's bundled
  # rule into that generated tree without modifying its contents.
  vendorUdevRules = pkgs.runCommand "azeron-software-udev-rules" { } ''
    mkdir -p "$out/lib/udev/rules.d"
    cp \
      "${azeronSoftware.appimageContents}/linux/udev/99-azeron-devices.rules" \
      "$out/lib/udev/rules.d/99-azeron-devices.rules"
  '';
in
{
  environment.systemPackages = [ azeronSoftware ];
  services.udev.packages = [ vendorUdevRules ];
}
