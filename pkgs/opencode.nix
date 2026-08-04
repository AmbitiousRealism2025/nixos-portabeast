{
  appimageTools,
  fetchurl,
  lib,
  stdenvNoCC,
}:

let
  version = "1.18.12";

  cli = stdenvNoCC.mkDerivation {
    pname = "opencode";
    inherit version;

    src = fetchurl {
      url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-linux-x64.tar.gz";
      hash = "sha256-ei47cGMGsE+/U1O2fZFrCAH82lZfnuAhvqKncgeWFFI=";
    };

    unpackPhase = "tar -xzf $src";

    installPhase = ''
      install -D -m 755 opencode $out/bin/opencode
    '';

    meta = {
      description = "OpenCode terminal coding agent";
      homepage = "https://opencode.ai/";
      license = lib.licenses.mit;
      platforms = [ "x86_64-linux" ];
      mainProgram = "opencode";
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    };
  };

  desktop = appimageTools.wrapType2 {
    pname = "opencode-desktop";
    inherit version;

    src = fetchurl {
      url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-desktop-linux-x86_64.AppImage";
      hash = "sha256-HMK6YasBK1Wz0lqpwLk3imPxLnFY9kbXsDif9zvBp9w=";
    };

    meta = {
      description = "OpenCode desktop application";
      homepage = "https://opencode.ai/";
      license = lib.licenses.mit;
      platforms = [ "x86_64-linux" ];
      mainProgram = "opencode-desktop";
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    };
  };
in
{
  inherit cli desktop;
}
