{ appimageTools, fetchurl, lib }:

let
  pname = "traycer-desktop";
  version = "1.1.9";
  src = fetchurl {
    url = "https://github.com/traycerai/traycer/releases/download/desktop-v${version}/traycer-desktop-linux-x86_64.AppImage";
    hash = "sha256-0C0+c5CFYIYdDLakjJ0G1OcibtMMBxCHBzvhuu+YnTs=";
  };
  appimageContents = appimageTools.extractType2 {
    inherit pname src version;
  };
in
appimageTools.wrapType2 {
  inherit pname src version;

  extraInstallCommands = ''
    for size in 16 24 32 48 64 128 256 512; do
      install -m 444 -D \
        ${appimageContents}/usr/share/icons/hicolor/"$size"x"$size"/apps/traycer-desktop.png \
        "$out/share/icons/hicolor/''${size}x''${size}/apps/traycer-desktop.png"
    done
  '';

  meta = {
    description = "Traycer Desktop, with its user-managed local Traycer Host";
    homepage = "https://traycer.ai/";
    platforms = [ "x86_64-linux" ];
    mainProgram = "traycer-desktop";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
