{ appimageTools, fetchurl, lib }:

appimageTools.wrapType2 rec {
  pname = "traycer-desktop";
  version = "1.1.9";
  src = fetchurl {
    url = "https://github.com/traycerai/traycer/releases/download/desktop-v${version}/traycer-desktop-linux-x86_64.AppImage";
    hash = "sha256-0C0+c5CFYIYdDLakjJ0G1OcibtMMBxCHBzvhuu+YnTs=";
  };
  meta = {
    description = "Traycer Desktop, with its user-managed local Traycer Host";
    homepage = "https://traycer.ai/";
    platforms = [ "x86_64-linux" ];
    mainProgram = "traycer-desktop";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
