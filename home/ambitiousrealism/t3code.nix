{ t3code, ... }:

{
  home.packages = [ t3code ];

  xdg.desktopEntries.t3code = {
    name = "T3 Code";
    comment = "Desktop interface for coding agents";
    exec = "${t3code}/bin/t3code";
    icon = "utilities-terminal";
    terminal = false;
    categories = [ "Development" "IDE" ];
  };
}
