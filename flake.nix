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

    # Persist the community desktop wrapper and pin the same official Codex
    # CLI version that was proven during bootstrap.
    codex-desktop-linux.url = "github:ilysenko/codex-desktop-linux";
    codex-nixpkgs.url = "https://releases.nixos.org/nixpkgs/nixpkgs-26.11pre1046984.104240a77242/nixexprs.tar.xz";

    # Pin the reviewed, signed Voxtype v0.7.5 release commit. Keep its own
    # upstream-tested nixpkgs lock rather than changing the package underneath
    # this exact source revision.
    voxtype.url = "github:peteonrails/voxtype/8d49248baa53f29cb33007c9625a37281c72e799";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      codex-desktop-linux,
      codex-nixpkgs,
      voxtype,
      ...
    }:
    let
      system = "x86_64-linux";
      helium = nixpkgs.legacyPackages.${system}.callPackage ./pkgs/helium.nix { };
      opencode = nixpkgs.legacyPackages.${system}.callPackage ./pkgs/opencode.nix { };
      t3code = nixpkgs.legacyPackages.${system}.callPackage ./pkgs/t3code.nix { };
    in
    {
      # eval-config reads the release's own .version-suffix and .git-revision.
      # nixpkgs.lib.nixosSystem instead derives these fields from flake source
      # metadata, which a release tarball intentionally does not carry.
      nixosConfigurations.nixos = import (nixpkgs + "/nixos/lib/eval-config.nix") {
        inherit system;
        specialArgs = { inherit helium opencode t3code; };
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          codex-desktop-linux.nixosModules.default
          {
            environment.systemPackages = [ codex-nixpkgs.legacyPackages.x86_64-linux.codex ];
            home-manager.extraSpecialArgs = {
              inherit voxtype helium opencode t3code;
            };
            programs.codexDesktopLinux = {
              enable = true;
              cliPackage = codex-nixpkgs.legacyPackages.x86_64-linux.codex;
            };
          }
        ];
      };

      formatter.x86_64-linux = nixpkgs.legacyPackages.${system}.nixfmt;
    };
}
