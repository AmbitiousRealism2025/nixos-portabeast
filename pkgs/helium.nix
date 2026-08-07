{
  appimageTools,
  fetchurl,
  lib,
}:

appimageTools.wrapType2 rec {
  pname = "helium";
  version = "0.15.1.1";

  src = fetchurl {
    url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64.AppImage";
    hash = "sha256-qz3w+nnvBgkpHT3E34dv4DvFuYlyzTAyg9tPYJFWs3o=";
  };

  meta = {
    description = "Privacy-focused Chromium-based browser";
    homepage = "https://github.com/imputnet/helium-linux";
    license = lib.licenses.bsd3;
    platforms = [ "x86_64-linux" ];
    mainProgram = "helium";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
