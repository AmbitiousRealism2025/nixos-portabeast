{
  albion,
  appimageTools,
  codexCli,
  cursorCli,
  fetchurl,
  lib,
  python3,
  runCommand,
  writeShellApplication,
  writeShellScriptBin,
}:

let
  pname = "t3code";
  version = "0.0.33";
  src = fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-x86_64.AppImage";
    hash = "sha256-QVyGSPQ8PSLVcvJ/LFD9yMMQ6n/N6VN7kD4eLxyHdaE=";
  };
  appimageContents = appimageTools.extractType2 {
    inherit pname src version;
  };

  base = appimageTools.wrapType2 {
    inherit pname src version;

    # The AppImage runs in an FHS environment that reconstructs PATH, so an
    # outer launcher prefix alone is not reliable. Expose provider launchers
    # inside the sandbox where T3 performs executable discovery.
    extraPkgs = _pkgs: [
      albion
      cursorAgentForT3
    ];

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
  # Retain the former `agent` command as a compatibility launcher while the
  # current nixpkgs package exposes `cursor-agent`.
  cursorAgentForT3 = writeShellScriptBin "agent" ''
    exec ${cursorCli}/bin/cursor-agent "$@"
  '';
  launcher = writeShellScriptBin "t3code" ''
    export PATH=${codexForT3}/bin:${albion}/bin:${cursorAgentForT3}/bin:$PATH
    exec ${base}/bin/t3code "$@"
  '';
in
runCommand "${pname}-${version}" { meta = base.meta; } ''
  test -x ${albion}/bin/claude
  test -x ${codexForT3}/bin/codex
  test -x ${cursorCli}/bin/cursor-agent
  test -x ${cursorAgentForT3}/bin/agent

  mkdir -p "$out/bin"
  ln -s ${launcher}/bin/t3code "$out/bin/t3code"

  icon=${appimageContents}/usr/share/icons/hicolor/512x512/apps/t3code.png
  test -f "$icon"
  install -m 444 -D "$icon" \
    "$out/share/icons/hicolor/512x512/apps/t3code.png"
''
