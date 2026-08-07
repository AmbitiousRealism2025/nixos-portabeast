{
  appimageTools,
  fetchurl,
  lib,
}:

let
  pname = "azeron-software";
  version = "2.0.1";

  src = fetchurl {
    url = "https://azeron-software-public.s3.us-east-1.amazonaws.com/live/2.0.1/Azeron-Software-v2.0.1.AppImage";
    hash = "sha256-bTMNLzf0Kt/iqL0bcEnjG7J5I8v1hT0khzH2Z6GocjA=";
  };

  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # Let the application confirm that its own declaratively installed udev
  # file is present instead of offering an in-app pkexec installation.
  extraBwrapArgs = [ "--ro-bind-try /etc/udev /etc/udev" ];

  extraInstallCommands = ''
    install -Dm444 \
      ${appimageContents}/azeron-software.desktop \
      "$out/share/applications/azeron-software.desktop"
    substituteInPlace "$out/share/applications/azeron-software.desktop" \
      --replace-fail 'Exec=AppRun --no-sandbox %U' \
                     'Exec=azeron-software --no-sandbox %U'

    for size in 64 128 256; do
      install -Dm444 \
        "${appimageContents}/usr/share/icons/hicolor/''${size}x''${size}/apps/azeron-software.png" \
        "$out/share/icons/hicolor/''${size}x''${size}/apps/azeron-software.png"
    done
  '';

  passthru = { inherit appimageContents; };

  meta = {
    description = "Configuration software for Azeron gaming keypads";
    homepage = "https://azeron.com/pages/software";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = pname;
  };
}
