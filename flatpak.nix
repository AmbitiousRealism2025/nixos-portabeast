{ ... }:

{
  # GeForce NOW is the sole planned Flatpak application. The application and
  # its repository remain user-scoped; NixOS supplies only the Flatpak runtime
  # integration, D-Bus services, export paths, and existing desktop portals.
  services.flatpak.enable = true;
}
