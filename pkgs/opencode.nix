{
  appimageTools,
  fetchurl,
  lib,
  opencode,
}:

let
  pname = "opencode-desktop";
  desktopVersion = "1.18.12";
  src = fetchurl {
    url = "https://github.com/anomalyco/opencode/releases/download/v${desktopVersion}/opencode-desktop-linux-x86_64.AppImage";
    hash = "sha256-HMK6YasBK1Wz0lqpwLk3imPxLnFY9kbXsDif9zvBp9w=";
  };
  appimageContents = appimageTools.extractType2 {
    inherit pname src;
    version = desktopVersion;
  };

  desktop = appimageTools.wrapType2 {
    inherit pname src;
    version = desktopVersion;

    extraInstallCommands = ''
      for size in 32 64 128; do
        install -m 444 -D \
          ${appimageContents}/usr/share/icons/hicolor/"$size"x"$size"/apps/ai.opencode.desktop.png \
          "$out/share/icons/hicolor/''${size}x''${size}/apps/ai.opencode.desktop.png"
      done
    '';

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
