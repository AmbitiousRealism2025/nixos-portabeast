{
  description = "Calamares-faithful NixOS configuration for the ThinkPad P1 Gen 4";

  # Use the immutable release source that produced the installed system. The
  # GitHub commit has the same revision but a development-style version suffix,
  # which prevents an exact top-level store-path comparison.
  inputs = {
    nixpkgs.url = "https://releases.nixos.org/nixos/26.05/nixos-26.05.6815.531670d871c0/nixexprs.tar.xz";

    # The release pin above is frozen at NVIDIA 595.71.05. This narrow second
    # source supplies the upstream 595.84 RTD3 fix together with its matching
    # Linux 7.1.6 kernel, without advancing the desktop or application set.
    nvidia-nixpkgs.url = "github:NixOS/nixpkgs/e72e4f299401a3689d4b3d5fc6496b11db7064eb";

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
      nvidia-nixpkgs,
      home-manager,
      codex-desktop-linux,
      codex-nixpkgs,
      voxtype,
      ...
    }:
    let
      system = "x86_64-linux";
      nvidiaPkgs = import nvidia-nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      unfreePkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      codexCli = codex-nixpkgs.legacyPackages.${system}.codex;
      cursorCli = unfreePkgs.cursor-cli;
      claudeCode = unfreePkgs.callPackage ./pkgs/claude-code.nix { };
      albion = unfreePkgs.callPackage ./pkgs/albion.nix { inherit claudeCode; };
      azeronSoftware = unfreePkgs.callPackage ./pkgs/azeron-software.nix { };
      cliproxyapi = unfreePkgs.callPackage ./pkgs/cliproxyapi.nix { };
      claudex = unfreePkgs.callPackage ./pkgs/claudex.nix {
        inherit
          claudeCode
          cliproxyapi
          codexCli
          ;
      };
      helium = nixpkgs.legacyPackages.${system}.callPackage ./pkgs/helium.nix { };
      nemoPreview = nixpkgs.legacyPackages.${system}.nemo-preview.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./home/ambitiousrealism/nemo-preview-wayland.patch ];
      });
      opencode = nixpkgs.legacyPackages.${system}.callPackage ./pkgs/opencode.nix { };
      piCli = nixpkgs.legacyPackages.${system}.callPackage ./pkgs/pi-coding-agent.nix { };
      primeAgentRuntime = nixpkgs.legacyPackages.${system}.callPackage ./pkgs/prime-agent-runtime.nix { };
      primeAgent = nixpkgs.legacyPackages.${system}.callPackage ./pkgs/prime-agent.nix {
        inherit primeAgentRuntime;
      };
      swiftpointX1 = unfreePkgs.callPackage ./pkgs/swiftpoint-x1.nix { };
      t3code = nixpkgs.legacyPackages.${system}.callPackage ./pkgs/t3code.nix {
        inherit albion codexCli cursorCli;
      };
      traycer = nixpkgs.legacyPackages.${system}.callPackage ./pkgs/traycer.nix { };
    in
    {
      packages.${system} = {
        inherit
          albion
          azeronSoftware
          claudex
          cliproxyapi
          primeAgent
          swiftpointX1
          ;
        claude-code = claudeCode;
      };

      # eval-config reads the release's own .version-suffix and .git-revision.
      # nixpkgs.lib.nixosSystem instead derives these fields from flake source
      # metadata, which a release tarball intentionally does not carry.
      nixosConfigurations.nixos = import (nixpkgs + "/nixos/lib/eval-config.nix") {
        inherit system;
        specialArgs = {
          inherit
            claudeCode
            albion
            azeronSoftware
            claudex
            helium
            nemoPreview
            nvidiaPkgs
            opencode
            piCli
            primeAgent
            swiftpointX1
            t3code
            traycer
            ;
        };
        modules = [
          ./configuration.nix
          home-manager.nixosModules.home-manager
          codex-desktop-linux.nixosModules.default
          {
            environment.systemPackages = [
              codexCli
              cursorCli
            ];
            home-manager.extraSpecialArgs = {
              inherit
                claudeCode
                albion
                claudex
                voxtype
                helium
                nemoPreview
                opencode
                t3code
                traycer
                ;
            };
            programs.codexDesktopLinux = {
              enable = true;
              cliPackage = codexCli;
            };
          }
        ];
      };

      formatter.x86_64-linux = nixpkgs.legacyPackages.${system}.nixfmt;
    };
}
