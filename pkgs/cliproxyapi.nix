{
  buildGoModule,
  fetchFromGitHub,
  lib,
}:

buildGoModule rec {
  pname = "cliproxyapi";
  version = "7.2.80";

  src = fetchFromGitHub {
    owner = "router-for-me";
    repo = "CLIProxyAPI";
    rev = "09da52ad509e2c18e7b9540db3b98c2214c280aa";
    hash = "sha256-becB1mP/n5uqySpYr9fW5veT1Z08os6y5KrttLAj/VY=";
  };

  vendorHash = "sha256-xirNOpnPVwe/TqEYkHHLMWREajosaisBazvy8rFEIak=";
  subPackages = [ "cmd/server" ];
  doCheck = false;

  ldflags = [
    "-s"
    "-w"
    "-X=main.Version=${version}"
    "-X=main.Commit=09da52ad509e2c18e7b9540db3b98c2214c280aa"
  ];

  postInstall = ''
    mv "$out/bin/server" "$out/bin/cliproxyapi"
  '';

  meta = {
    description = "Multi-provider compatibility API used by Claudex";
    homepage = "https://github.com/router-for-me/CLIProxyAPI";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "cliproxyapi";
  };
}
