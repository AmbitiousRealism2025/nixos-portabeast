{ lib, pkgs, traycer, ... }:
let
  # Traycer downloads its Host binary into ~/.traycer and starts it through a
  # user systemd unit.  The upstream binary uses the conventional Linux ELF
  # loader path, which NixOS deliberately does not provide globally.  Keep the
  # compatibility boundary to this single Host service rather than enabling a
  # system-wide generic-binary loader.
  traycerHost = pkgs.writeShellScriptBin "traycer-host-nixos" ''
    set -eu

    cli="$HOME/.traycer/cli/bin/traycer"
    loader="${pkgs.stdenv.cc.bintools.dynamicLinker}"
    library_path="${lib.makeLibraryPath [ pkgs.stdenv.cc.cc ]}"
    patchelf="${pkgs.patchelf}/bin/patchelf"

    patch_generic_linux_binary() {
      binary="$1"
      [ -x "$binary" ] || return 0

      interpreter="$("$patchelf" --print-interpreter "$binary" 2>/dev/null || true)"
      if [ "$interpreter" = /lib64/ld-linux-x86-64.so.2 ]; then
        "$patchelf" \
          --set-interpreter "$loader" \
          --set-rpath "$library_path" \
          "$binary"
      fi
    }

    if [ ! -x "$cli" ]; then
      echo "Traycer Host binary is not installed yet: $cli" >&2
      exit 1
    fi

    # The Host installer writes this second native executable outside the
    # AppImage.  Patch only these Traycer-owned copies, never the global loader
    # policy or arbitrary user executables.  Recheck on every service start so
    # a downloaded Host update is corrected on its next restart.
    patch_generic_linux_binary "$cli"
    patch_generic_linux_binary "$HOME/.traycer/host/install/host-runtime/traycer-host"

    if "$loader" --library-path "$library_path" "$cli" host capabilities --has service-label >/dev/null 2>&1; then
      exec "$cli" host start --service-label ai.traycer.host
    else
      exec "$cli" host start
    fi
  '';
in
{
  home.packages = [ traycer ];

  # Traycer owns the base unit, so use a separate declarative drop-in.  It
  # survives Host updates while preserving all upstream unit settings.
  xdg.configFile."systemd/user/ai.traycer.host.service.d/10-nixos.conf".text = ''
    [Service]
    ExecStart=
    ExecStart=${traycerHost}/bin/traycer-host-nixos
  '';

  xdg.desktopEntries.traycer = {
    name = "Traycer";
    comment = "Spec-driven development desktop app";
    exec = "${traycer}/bin/traycer-desktop";
    icon = "traycer-desktop";
    terminal = false;
    categories = [ "Development" "IDE" ];
  };
}
