{ pkgs, swiftpointX1, ... }:

let
  # NixOS owns /etc/udev/rules.d as a read-only generated tree, so install the
  # vendor's file through the udev package mechanism without altering it.
  vendorUdevRules = pkgs.runCommand "swiftpoint-x1-udev-rules" { } ''
    mkdir -p "$out/lib/udev/rules.d"
    cp \
      "${swiftpointX1.payload}/share/swiftpoint-x1/60-Swiftpoint.rules" \
      "$out/lib/udev/rules.d/60-Swiftpoint.rules"
  '';
in
{
  environment.systemPackages = [ swiftpointX1 ];

  services.udev.packages = [ vendorUdevRules ];
}
