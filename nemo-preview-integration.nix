{ nemoPreview, ... }:

{
  # Register the patched previewer with the session bus so Nemo can start it
  # on demand the first time Space is pressed.
  services.dbus.packages = [ nemoPreview ];
}
