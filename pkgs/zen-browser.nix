{
  appimageTools,
  fetchurl,
  lib,
  makeWrapper,
}:

let
  pname = "zen";
  version = "1.21.10b";
  src = fetchurl {
    url = "https://github.com/zen-browser/desktop/releases/download/${version}/zen-x86_64.AppImage";
    hash = "sha256-T6aOSwBL+f4qxKtERnYcBirTxWZV6KWr3crVgqHlcoM=";
  };
  appimageContents = appimageTools.extractType2 {
    inherit pname src version;
  };
in
appimageTools.wrapType2 {
  inherit pname src version;

  # Firefox-family browsers load FFmpeg dynamically for H.264/AAC playback.
  # Keep Zen on FFmpeg 7 because its current Linux build is incompatible with
  # FFmpeg 8, which otherwise breaks some YouTube live streams.
  extraPkgs = pkgs: [ pkgs.ffmpeg_7 ];

  nativeBuildInputs = [ makeWrapper ];

  extraInstallCommands = ''
    install -m 444 -D \
      ${appimageContents}/zen.desktop \
      $out/share/applications/zen.desktop
    install -m 444 -D \
      ${appimageContents}/zen.png \
      $out/share/icons/hicolor/128x128/apps/zen.png

    # The Intel GPU owns the desktop. Keep the browser on native Wayland and
    # explicitly opt it out of PRIME render offload; NVIDIA remains available
    # only to applications launched through the reviewed offload route.
    wrapProgram $out/bin/zen \
      --set MOZ_ENABLE_WAYLAND 1 \
      --set DRI_PRIME 0 \
      --set __NV_PRIME_RENDER_OFFLOAD 0 \
      --set __GLX_VENDOR_LIBRARY_NAME mesa
  '';

  meta = {
    description = "Firefox-based browser focused on a calm, productive experience";
    homepage = "https://zen-browser.app/";
    downloadPage = "https://github.com/zen-browser/desktop/releases/tag/${version}";
    license = lib.licenses.mpl20;
    mainProgram = "zen";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
