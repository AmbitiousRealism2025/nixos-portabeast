{ opencode, ... }:

{
  home.packages = [
    opencode.cli
    opencode.desktop
  ];

  # Keep the graphical release discoverable in DMS without changing the
  # existing Codex Desktop entry or any browser/application defaults.
  xdg.desktopEntries.opencode = {
    name = "OpenCode";
    comment = "OpenCode desktop coding agent";
    exec = "${opencode.desktop}/bin/opencode-desktop";
    icon = "ai.opencode.desktop";
    terminal = false;
    categories = [ "Development" "IDE" ];
  };
}
