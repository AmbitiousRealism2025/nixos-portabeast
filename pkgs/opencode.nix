{
  appimageTools,
  fetchurl,
  lib,
  makeWrapper,
  stdenv,
}:

let
  pname = "opencode-desktop";
  version = "1.18.16";
  src = fetchurl {
    url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-desktop-linux-x86_64.AppImage";
    hash = "sha256-QBJEz1ElqsiYK5hy4RIws9uefDIZOAUSYnes+yP5bzo=";
  };
  cliSrc = fetchurl {
    url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-linux-x64.tar.gz";
    hash = "sha256-KG4HNV3wZzjBkFlVvhW3+8EKexLZMd6TlKb3WXJGdQs=";
  };
  appimageContents = appimageTools.extractType2 {
    inherit pname src;
    inherit version;
  };

  desktop = appimageTools.wrapType2 {
    inherit pname src;
    inherit version;

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
  cli = stdenv.mkDerivation {
    pname = "opencode";
    inherit version;
    src = cliSrc;

    unpackPhase = ''
      runHook preUnpack
      tar -xzf "$src"
      runHook postUnpack
    '';

    nativeBuildInputs = [ makeWrapper ];
    dontBuild = true;
    dontPatchELF = true;
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 opencode "$out/libexec/opencode/opencode"
      makeWrapper ${stdenv.cc.bintools.dynamicLinker} "$out/bin/opencode" \
        --add-flags "$out/libexec/opencode/opencode" \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ stdenv.cc.libc ]}
      runHook postInstall
    '';

    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck
      checkHome="$TMPDIR/opencode-check-home"
      mkdir -p "$checkHome"
      cd "$checkHome"
      set +e
      actualVersion="$(HOME="$checkHome" TMPDIR="$checkHome" "$out/bin/opencode" --version 2>&1)"
      versionStatus=$?
      set -e
      echo "OpenCode CLI version (status $versionStatus): $actualVersion"
      test "$versionStatus" -eq 0
      test "$actualVersion" = "${version}"
      runHook postInstallCheck
    '';

    meta = {
      description = "Open source coding agent";
      homepage = "https://opencode.ai/";
      license = lib.licenses.mit;
      mainProgram = "opencode";
      platforms = [ "x86_64-linux" ];
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    };
  };
in
{
  inherit cli desktop;
}
