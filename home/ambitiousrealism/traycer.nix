{ traycer, ... }:
{
  home.packages = [ traycer ];
  xdg.desktopEntries.traycer = {
    name = "Traycer";
    comment = "Spec-driven development desktop app";
    exec = "${traycer}/bin/traycer-desktop";
    icon = "utilities-terminal";
    terminal = false;
    categories = [ "Development" "IDE" ];
  };
}
