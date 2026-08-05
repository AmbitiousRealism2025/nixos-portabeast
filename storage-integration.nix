{ lib, ... }:

{
  # Expose the fixed Kingston data drive through the standard GIO/GVfs device
  # layer used by Nemo and other GTK file managers. The drive remains mounted
  # at /mnt/storage by its existing hardware declaration.
  services.gvfs.enable = true;

  fileSystems."/mnt/storage".options = lib.mkAfter [
    "x-gvfs-show"
    "x-gvfs-name=Kingston%201TB"
  ];
}
