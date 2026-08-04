{ helium, ... }:

{
  home.packages = [ helium ];

  # This makes Helium discoverable in DMS without changing any MIME defaults:
  # Zen stays the system's default browser and 1Password trust remains scoped
  # to the already-reviewed Zen policy.
  xdg.desktopEntries.helium = {
    name = "Helium";
    comment = "Privacy-focused Chromium browser";
    exec = "${helium}/bin/helium";
    icon = "web-browser";
    terminal = false;
    categories = [ "Network" "WebBrowser" ];
  };
}
