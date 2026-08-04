{ t3code, ... }:

{
  home.packages = [ t3code ];

  # The DMS service receives the declarative system path containing Codex CLI.
  # Do not copy credentials or configure providers here; T3 Code discovers the
  # existing user-owned CLI after its first normal launch.
  xdg.desktopEntries.t3code = {
    name = "T3 Code";
    comment = "Desktop interface for coding agents";
    exec = "${t3code}/bin/t3code";
    icon = "utilities-terminal";
    terminal = false;
    categories = [ "Development" "IDE" ];
  };
}
