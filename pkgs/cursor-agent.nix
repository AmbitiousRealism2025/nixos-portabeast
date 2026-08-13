{
  autoPatchelfHook,
  fetchurl,
  lib,
  stdenv,
  zlib,
}:

stdenv.mkDerivation {
  pname = "cursor-cli";
  version = "2026.08.11-e8db854";

  src = fetchurl {
    url = "https://downloads.cursor.com/lab/2026.08.11-e8db854/linux/x64/agent-cli-package.tar.gz";
    hash = "sha256-v/9L9vTp3TDB0O8KcLYHewdAFd0pSOTFBoXVOv3Pzlo=";
  };

  sourceRoot = "dist-package";
  buildInputs = [ zlib ];
  nativeBuildInputs = [
    autoPatchelfHook
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/share/cursor-agent"
    cp -r . "$out/share/cursor-agent/"
    ln -s "$out/share/cursor-agent/cursor-agent" "$out/bin/cursor-agent"

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    test "$(HOME="$TMPDIR" "$out/bin/cursor-agent" --version)" = "2026.08.11-e8db854"
    runHook postInstallCheck
  '';

  meta = {
    description = "Cursor Agent CLI";
    homepage = "https://cursor.com/cli";
    license = lib.licenses.unfree;
    mainProgram = "cursor-agent";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
