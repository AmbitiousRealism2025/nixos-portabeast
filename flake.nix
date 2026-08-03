{
  description = "Calamares-faithful NixOS configuration for the ThinkPad P1 Gen 4";

  # Use the immutable release source that produced the installed system. The
  # GitHub commit has the same revision but a development-style version suffix,
  # which prevents an exact top-level store-path comparison.
  inputs = {
    nixpkgs.url = "https://releases.nixos.org/nixos/26.05/nixos-26.05.6815.531670d871c0/nixexprs.tar.xz";

    home-manager = {
      url = "github:nix-community/home-manager/d4fd24667c8cbef124bb70a20380cab75ec8474d";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      ...
    }:
    {
      # eval-config reads the release's own .version-suffix and .git-revision.
      # nixpkgs.lib.nixosSystem instead derives these fields from flake source
      # metadata, which a release tarball intentionally does not carry.
      nixosConfigurations.nixos = import (nixpkgs + "/nixos/lib/eval-config.nix") {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
        ];
      };

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt;
    };
}
