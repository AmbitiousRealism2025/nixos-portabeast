{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [ ./hardware-configuration.nix ];

  # Preserve the working Calamares bootloader configuration.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Preserve the currently selected kernel family.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Compressed in-memory swap only. The Calamares installation intentionally
  # has no disk swap and hibernation remains out of scope.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  services.xserver.enable = true;
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Plasma enables a system-wide DrKonqi handoff for every systemd coredump.
  # During UWSM teardown its GUI launcher has no display and can coredump
  # recursively. Keep systemd-coredump and coredumpctl, but disable this
  # automatic GUI handoff until the upstream lifecycle bug is resolved.
  systemd.services."drkonqi-coredump-processor@".wantedBy = lib.mkForce [ ];

  # Add Hyprland beside Plasma in SDDM. UWSM is the sole primary session
  # manager; the direct Hyprland entry remains available for recovery.
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  # Make backend selection deterministic for both installed desktops. Plasma
  # keeps its KDE/KWallet integration; Hyprland uses XDPH for compositor-aware
  # interfaces and GTK as the general fallback.
  xdg.portal.config = {
    kde = {
      default = [ "kde" ];
      "org.freedesktop.impl.portal.Settings" = [
        "kde"
        "gtk"
      ];
      "org.freedesktop.impl.portal.Secret" = [ "kwallet" ];
    };
    hyprland = {
      default = [
        "hyprland"
        "gtk"
      ];
      "org.freedesktop.impl.portal.Secret" = [ "kwallet" ];
    };
    common.default = [ "gtk" ];
  };

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.ambitiousrealism = {
    isNormalUser = true;
    description = "Sean Murphy";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = with pkgs; [ kdePackages.kate ];
  };

  # NixOS owns the login shell and Home Manager owns the interactive Zsh
  # configuration. No Fish package or Fish state is imported.
  programs.zsh.enable = true;
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.ambitiousrealism = import ./home/ambitiousrealism;
  };

  programs.firefox.enable = true;

  # Match the effective Calamares generation. The immutable release tarball
  # used by this flake contains programs.sqlite and would otherwise change this
  # source-dependent default from false to true.
  programs.command-not-found.enable = false;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    git
    pciutils
    usbutils
  ];

  system.stateVersion = "26.05";
}
