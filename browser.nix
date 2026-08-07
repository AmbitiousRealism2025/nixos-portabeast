{ pkgs, ... }:

let
  zenBrowser = pkgs.callPackage ./pkgs/zen-browser.nix { };
in
{
  # Zen is the selected browser. Firefox remains installed through its NixOS
  # module as an independently packaged recovery browser.
  environment.systemPackages = [ zenBrowser ];
}
