{
  bash,
  claudeCode,
  coreutils,
  curl,
  fetchFromGitHub,
  findutils,
  gawk,
  git,
  gnugrep,
  gnused,
  lib,
  makeWrapper,
  python3,
  stdenvNoCC,
  tmux,
}:

stdenvNoCC.mkDerivation rec {
  pname = "albion";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "AmbitiousRealism2025";
    repo = "Albion";
    rev = "63c084cc35f9f5c172441cb2069fc6e515956e58";
    hash = "sha256-eLueo0VAvEbLp2GXPEWVZSDEOiW4YoZE81oBpNbX0Co=";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase =
    let
      runtimePath = lib.makeBinPath [
        bash
        claudeCode
        coreutils
        curl
        findutils
        gawk
        git
        gnugrep
        gnused
        python3
        tmux
      ];
    in
    ''
      runHook preInstall

      mkdir -p "$out/share/albion" "$out/bin"
      cp -R bin charter config env manifest plugin state "$out/share/albion/"
      mkdir -p "$out/share/albion/tests/tools" "$out/share/albion/tests/fixtures"
      cp -R tests/tools/capture "$out/share/albion/tests/tools/"
      cp -R tests/fixtures/hooks "$out/share/albion/tests/fixtures/"
      chmod -R u+w "$out/share/albion"
      patchShebangs "$out/share/albion"

      # Keep provider state separate from stock Claude Code and source the
      # mode-600 token file only for commands that contact or inspect Z.ai.
      for command in albion albion-doctor albion-vision; do
        makeWrapper "$out/share/albion/bin/$command" "$out/bin/$command" \
          --prefix PATH : "${runtimePath}" \
          --run 'export CLAUDE_CONFIG_DIR="''${ALBION_CLAUDE_CONFIG_DIR:-$HOME/.claude-albion}"' \
          --run 'albion_secrets="''${ALBION_SECRETS_FILE:-$HOME/.albion/secrets.sh}"; if [[ -r "$albion_secrets" ]]; then source "$albion_secrets"; fi; unset albion_secrets'
      done

      # Setup creates the private token file but deliberately does not source
      # an existing one. Compile is retained for its useful read-only --check.
      for command in albion-setup albion-compile; do
        makeWrapper "$out/share/albion/bin/$command" "$out/bin/$command" \
          --prefix PATH : "${runtimePath}"
      done

      substitute ${./albion-default-claude.sh} "$out/bin/claude" \
        --subst-var-by claudeCode ${claudeCode} \
        --subst-var-by albionLauncher "$out/bin/albion"
      substitute ${./claude-stock.sh} "$out/bin/claude-stock" \
        --subst-var-by claudeCode ${claudeCode}
      chmod +x "$out/bin/claude" "$out/bin/claude-stock"

      runHook postInstall
    '';

  doInstallCheck = true;
  installCheckPhase = ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    export ALBION_ZAI_TOKEN=test-only-token

    "$out/bin/albion" --dry-run > "$TMPDIR/albion-dry-run"
    grep -Fq 'auth_lane=plan' "$TMPDIR/albion-dry-run"
    grep -Fq 'model=glm-5.2[1m]' "$TMPDIR/albion-dry-run"
    grep -Fq "plugin-dir $out/share/albion/plugin" "$TMPDIR/albion-dry-run"
    grep -Fq "settings $out/share/albion/config/albion-settings.json" "$TMPDIR/albion-dry-run"
    "$out/bin/albion-compile" --check
    test "$("$out/bin/claude" --version)" = '2.1.222 (Claude Code)'
    test "$("$out/bin/claude-stock" --version)" = '2.1.222 (Claude Code)'
  '';

  meta = {
    description = "Claude Code orchestration layer for Z.ai GLM models";
    homepage = "https://github.com/AmbitiousRealism2025/Albion";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "albion";
  };
}
