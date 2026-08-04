{
  # Codex created this as mutable per-user state before browser management was
  # introduced. Replace it with the complete declarative file below; the Codex
  # deep-link association is retained explicitly.
  xdg.configFile."mimeapps.list".force = true;

  xdg.mimeApps = {
    enable = true;
    associations.added."x-scheme-handler/codex" = [ "codex-desktop.desktop" ];
    defaultApplications = {
      "text/html" = [ "zen.desktop" ];
      "application/xhtml+xml" = [ "zen.desktop" ];
      "x-scheme-handler/http" = [ "zen.desktop" ];
      "x-scheme-handler/https" = [ "zen.desktop" ];
      "x-scheme-handler/codex" = [ "codex-desktop.desktop" ];
    };
  };
}
