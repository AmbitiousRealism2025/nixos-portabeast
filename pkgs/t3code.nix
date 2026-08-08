{
  albion,
  appimageTools,
  codexCli,
  fetchurl,
  lib,
  python3,
  runCommand,
  writeShellApplication,
  writeShellScriptBin,
}:

let
  pname = "t3code";
  version = "0.0.24";
  src = fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-x86_64.AppImage";
    hash = "sha256-t8KYAtaQKWmCVOOwvHByosYoqb0Ji35Qe4m+8Gtp/+k=";
  };
  appimageContents = appimageTools.extractType2 {
    inherit pname src version;
  };

  base = appimageTools.wrapType2 {
    inherit pname src version;

    # The AppImage runs in an FHS environment that reconstructs PATH, so an
    # outer launcher prefix alone is not reliable. Expose Albion inside the
    # sandbox where T3 performs its Claude executable discovery.
    extraPkgs = _pkgs: [ albion ];

    meta = {
      description = "Desktop interface for coding agents";
      homepage = "https://t3.codes/";
      license = lib.licenses.mit;
      platforms = [ "x86_64-linux" ];
      mainProgram = "t3code";
      sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    };
  };

  codexForT3 = writeShellApplication {
    name = "codex";
    runtimeInputs = [ python3 ];
    text = ''
      exec ${python3}/bin/python3 ${./t3code-codex-proxy.py} \
        ${codexCli}/bin/codex "$@"
    '';
  };
  launcher = writeShellScriptBin "t3code" ''
    export PATH=${codexForT3}/bin:${albion}/bin:$PATH
    exec ${base}/bin/t3code "$@"
  '';
in
runCommand "${pname}-${version}" { meta = base.meta; } ''
  test -x ${albion}/bin/claude
  test -x ${codexForT3}/bin/codex

  mkdir -p "$out/bin"
  ln -s ${launcher}/bin/t3code "$out/bin/t3code"

  install -m 444 -D \
    ${appimageContents}/usr/share/icons/hicolor/1024x1024/apps/t3code.png \
    "$out/share/icons/hicolor/1024x1024/apps/t3code.png"
''
