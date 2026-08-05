{
  bash,
  claudeCode,
  cliproxyapi,
  codexCli,
  coreutils,
  curl,
  fetchFromGitHub,
  findutils,
  gawk,
  git,
  gnugrep,
  gnused,
  jq,
  lib,
  makeWrapper,
  nodejs,
  openssl,
  procps,
  stdenvNoCC,
  util-linux,
}:

stdenvNoCC.mkDerivation rec {
  pname = "claudex";
  version = "1.6.2";

  src = fetchFromGitHub {
    owner = "BeamoINT";
    repo = "Claudex";
    rev = "5410559ba344df0c2bd98f1e1ab40e5776600e24";
    hash = "sha256-rAtpERuKG11NhjhWuL0I2/vErRqar/4N2kJDgLYIEsU=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase =
    let
      runtimePath = lib.makeBinPath [
        bash
        coreutils
        curl
        findutils
        gawk
        git
        gnugrep
        gnused
        jq
        nodejs
        openssl
        procps
        util-linux
      ];
    in
    ''
      runHook preInstall

      mkdir -p "$out/bin" "$out/libexec/claudex-runtime/bin" "$out/share/claudex/skills/usage-limit"
      install -m 0755 claudex codex-session statusline usage-limit self-update "$out/share/claudex/"
      install -m 0644 preload.cjs skill-bridge.cjs settings.json "$out/share/claudex/"
      install -m 0644 skills/usage-limit/SKILL.md "$out/share/claudex/skills/usage-limit/SKILL.md"
      patchShebangs "$out/share/claudex"

      ln -s ${claudeCode}/bin/claude "$out/libexec/claudex-runtime/bin/claude"
      ln -s ${codexCli}/bin/codex "$out/libexec/claudex-runtime/bin/codex"

      substitute ${./claudex-nixos-setup.sh} "$out/libexec/claudex-nixos-setup" \
        --subst-var-by privateRuntime "$out/libexec/claudex-runtime/bin" \
        --subst-var-by runtimePath "${runtimePath}" \
        --subst-var-by proxyBin "${cliproxyapi}/bin/cliproxyapi" \
        --subst-var-by share "$out/share/claudex" \
        --subst-var-by bashBin "${bash}/bin/bash" \
        --subst-var-by version "${version}"
      chmod 0755 "$out/libexec/claudex-nixos-setup"

      substitute ${./claudex-wrapper.sh} "$out/bin/claudex" \
        --subst-var-by privateRuntime "$out/libexec/claudex-runtime/bin" \
        --subst-var-by runtimePath "${runtimePath}" \
        --subst-var-by setup "$out/libexec/claudex-nixos-setup" \
        --subst-var-by launcher "$out/share/claudex/claudex" \
        --subst-var-by version "${version}"
      chmod 0755 "$out/bin/claudex"

      makeWrapper "$out/libexec/claudex-nixos-setup" "$out/bin/claudex-setup" \
        --prefix PATH : "$out/libexec/claudex-runtime/bin:${runtimePath}"

      runHook postInstall
    '';

  doInstallCheck = true;
  installCheckPhase = ''
    ${bash}/bin/bash -n "$out/bin/claudex" "$out/libexec/claudex-nixos-setup"
    ${bash}/bin/bash -n \
      "$out/share/claudex/claudex" \
      "$out/share/claudex/codex-session" \
      "$out/share/claudex/statusline" \
      "$out/share/claudex/usage-limit"
    ${nodejs}/bin/node --check "$out/share/claudex/preload.cjs"
    ${nodejs}/bin/node --check "$out/share/claudex/skill-bridge.cjs"

    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    "$out/bin/claudex-setup" >/dev/null
    test "$(stat -c %a "$HOME/.config/claudex")" = 700
    test "$(stat -c %a "$HOME/.config/claudex/env")" = 600
    test "$(stat -c %a "$HOME/.config/claudex/cliproxyapi.yaml")" = 600
    grep -Fq 'host: "127.0.0.1"' "$HOME/.config/claudex/cliproxyapi.yaml"
    grep -Fq 'CLAUDEX_AUTO_UPDATE=off' "$HOME/.config/claudex/env"
    test "$("${cliproxyapi}/bin/cliproxyapi" -version 2>&1 | head -1)" = \
      'CLIProxyAPI Version: 7.2.80, Commit: 09da52ad509e2c18e7b9540db3b98c2214c280aa, BuiltAt: unknown'
  '';

  meta = {
    description = "Claude Code compatibility layer for Codex GPT models";
    homepage = "https://github.com/BeamoINT/Claudex";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "claudex";
  };
}
