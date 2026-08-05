{ swiftpointX1, ... }:

{
  environment.systemPackages = [ swiftpointX1 ];

  # Swiftpoint's vendor archive grants its hidraw nodes mode 0666. Restrict
  # access to the active local graphical session instead while retaining all
  # Z3/SwiftLink runtime and bootloader IDs needed by the control panel.
  services.udev.extraRules = ''
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="214e", ATTRS{idProduct}=="0031", TAG+="uaccess"
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="214e", ATTRS{idProduct}=="0032", TAG+="uaccess"
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="214e", ATTRS{idProduct}=="0033", TAG+="uaccess"
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="214e", ATTRS{idProduct}=="0034", TAG+="uaccess"
    SUBSYSTEM=="hidraw", KERNELS=="0005:214E:0035*", TAG+="uaccess"

    # X1's keyboard-shortcut recorder needs active-session access to input
    # event devices. This mirrors the vendor's uaccess rule without changing
    # their persistent owner, group, or mode.
    KERNEL=="event*", SUBSYSTEM=="input", TAG+="uaccess"
  '';
}
