{
  appimageTools,
  codexCli,
  fetchurl,
  lib,
  python3,
  writeShellApplication,
  writeShellScriptBin,
}:

let
  base = appimageTools.wrapType2 rec {
    pname = "t3code";
    version = "0.0.24";

    src = fetchurl {
      url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-x86_64.AppImage";
      hash = "sha256-t8KYAtaQKWmCVOOwvHByosYoqb0Ji35Qe4m+8Gtp/+k=";
    };

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
in
writeShellScriptBin "t3code" ''
  export PATH=${codexForT3}/bin:$PATH
  exec ${base}/bin/t3code "$@"
''
