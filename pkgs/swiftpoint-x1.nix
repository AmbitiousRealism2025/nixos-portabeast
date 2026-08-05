{
  alsa-lib,
  buildFHSEnv,
  dbus,
  fetchurl,
  fontconfig,
  freetype,
  glib,
  krb5,
  lib,
  libdrm,
  libglvnd,
  libx11,
  libxkbcommon,
  libxcb,
  makeDesktopItem,
  stdenvNoCC,
  systemd,
  wayland,
  xcbutilcursor,
  xcbutilimage,
  xcbutilkeysyms,
  xcbutilrenderutil,
  xcbutilwm,
  zstd,
  zlib,
}:

let
  pname = "swiftpoint-x1";
  version = "3.1.2.0";

  payload = stdenvNoCC.mkDerivation {
    pname = "swiftpoint-x1-payload";
    inherit version;

    src = fetchurl {
      url = "https://swiftpointdrivers.blob.core.windows.net/pro/beta/linux/Swiftpoint%20X1%20Control%20Panel%203.1.2.0-75bd9042.tar.xz";
      hash = "sha256-AKAKmOL8jg6jKsWzTLAI/zmhd+keKPwpVRBw3tNxsEk=";
    };

    sourceRoot = "Swiftpoint X1 Control Panel 3.1.2.0";
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/bin" "$out/share/swiftpoint-x1"
      cp -R . "$out/share/swiftpoint-x1/"
      ln -s "$out/share/swiftpoint-x1/Swiftpoint X1 Control Panel" \
        "$out/bin/swiftpoint-x1-vendor"

      runHook postInstall
    '';
  };

  desktopItem = makeDesktopItem {
    name = pname;
    desktopName = "Swiftpoint X1 Control Panel";
    genericName = "Mouse Configuration";
    comment = "Configure the Swiftpoint Z3 and SwiftLink receiver";
    exec = "swiftpoint-x1";
    icon = "input-mouse";
    categories = [
      "Settings"
      "HardwareSettings"
    ];
    startupNotify = true;
  };
in
buildFHSEnv {
  inherit pname version;

  targetPkgs = pkgs: [
    payload
    alsa-lib
    dbus
    fontconfig
    freetype
    glib
    krb5
    libdrm
    libglvnd
    libx11
    libxkbcommon
    libxcb
    systemd
    wayland
    xcbutilcursor
    xcbutilimage
    xcbutilkeysyms
    xcbutilrenderutil
    xcbutilwm
    zstd
    zlib
  ];

  runScript = "${payload}/bin/swiftpoint-x1-vendor";

  extraInstallCommands = ''
    mkdir -p "$out/share/applications"
    ln -s ${desktopItem}/share/applications/${pname}.desktop \
      "$out/share/applications/${pname}.desktop"
  '';

  passthru = { inherit payload; };

  meta = {
    description = "Experimental Linux control panel for Swiftpoint Z-series mice";
    homepage = "https://support.swiftpoint.com/portal/en/kb/articles/x1-control-panel-linux";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = pname;
  };
}
