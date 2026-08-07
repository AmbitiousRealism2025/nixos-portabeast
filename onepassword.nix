{ pkgs, ... }:

let
  # Keep the release's reviewed NixOS integration and library set, replacing
  # only the two official vendor archives with their current stable releases.
  onePasswordCli = pkgs._1password-cli.overrideAttrs (_old: rec {
    version = "2.35.0";
    src = pkgs.fetchzip {
      url = "https://cache.agilebits.com/dist/1P/op2/pkg/v${version}/op_linux_amd64_v${version}.zip";
      hash = "sha256-xv3pFMKflVFgrleh6tMLpcyqASJjYxPRMWrd9p8+rhc=";
      stripRoot = false;
    };
  });

  onePasswordGui = pkgs._1password-gui.overrideAttrs (_old: {
    version = "8.12.28";
    src = pkgs.fetchurl {
      url = "https://downloads.1password.com/linux/tar/stable/x86_64/1password-8.12.28.x64.tar.gz";
      hash = "sha256-JpXXLpjAOfBh+oc1YIBxqBZha02IuzclVhQRiF29V6c=";
    };
  });
in
{
  programs._1password = {
    enable = true;
    package = onePasswordCli;
  };

  programs._1password-gui = {
    enable = true;
    package = onePasswordGui;
    polkitPolicyOwners = [ "ambitiousrealism" ];
  };

  # Zen is installed from a root-owned, immutable Nix store path. Trust only
  # that binary name for desktop-app integration; Firefox is already supported
  # by 1Password and does not belong in the additional-browser allow-list.
  environment.etc."1password/custom_allowed_browsers" = {
    text = ''
      zen
    '';
    mode = "0644";
    user = "root";
    group = "root";
  };
}
