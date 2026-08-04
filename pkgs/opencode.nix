{
  appimageTools,
  fetchurl,
  lib,
  opencode,
}:

let
  desktopVersion = "1.18.12";

  desktop = appimageTools.wrapType2 {
    pname = "opencode-desktop";
    version = desktopVersion;

    src = fetchurl {
      url = "https://github.com/anomalyco/opencode/releases/download/v${desktopVersion}/opencode-desktop-linux-x86_64.AppImage";
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
  # Nixpkgs builds this terminal agent from the OpenCode source tree. Do not
  # replace it with the current upstream Linux tarball: that archive was
  # verified to contain Bun rather than the OpenCode command.
  cli = opencode;
  inherit desktop;
}
