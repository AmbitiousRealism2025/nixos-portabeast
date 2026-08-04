{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./browser.nix
    ./onepassword.nix
  ];

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

  # Temporary safety containment for a measured NVIDIA suspend deadlock. The
  # laptop remained awake after a lid-close suspend attempt, drained its main
  # battery, and subsequently lost its RTC/firmware settings. Until the
  # NVIDIA sleep path is validated in a separate boot-only test, lid close
  # powers the undocked laptop off cleanly and every system sleep mode is
  # unavailable. A docked/external-display setup simply ignores lid close.
  services.logind.settings.Login = {
    HandleLidSwitch = "poweroff";
    HandleLidSwitchExternalPower = "poweroff";
    HandleLidSwitchDocked = "ignore";
  };

  systemd.sleep.settings.Sleep = {
    AllowSuspend = "no";
    AllowHibernation = "no";
    AllowHybridSleep = "no";
    AllowSuspendThenHibernate = "no";
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Keep the Intel GPU as the normal desktop renderer and expose the NVIDIA
  # T1200 through PRIME render offload for Vulkan/GL applications such as
  # Voxtype. The closed kernel module is intentional on this Turing laptop:
  # unlike the open module, it supports the runtime D3 power-management path
  # needed to let this generation of mobile GPU power down between offloads.
  hardware.graphics = {
    enable = true;
    enable32Bit = false;
    extraPackages = [ pkgs.intel-media-driver ];
  };

  services.xserver.videoDrivers = [
    "modesetting"
    "nvidia"
  ];

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    open = false;
    # Driver 595 enables GSP by default on Turing, but this T1200 reports RTD3
    # as unsupported while GSP is active. Use the proprietary module's native
    # management path so the reviewed fine-grained runtime power policy can be
    # tested without changing the driver or offload configuration.
    gsp.enable = false;
    moduleParams.nvidia.NVreg_EnableGpuFirmware = 0;
    modesetting.enable = true;
    powerManagement = {
      enable = true;
      finegrained = true;
    };
    prime = {
      intelBusId = "PCI:0@0:2:0";
      nvidiaBusId = "PCI:1@0:0:0";
      sync.enable = false;
      reverseSync.enable = false;
      offload = {
        enable = true;
        enableOffloadCmd = true;
        offloadCmdMainProgram = "nvidia-offload";
      };
    };
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

  # Install DMS without its generic graphical-session service. That upstream
  # target is also active in Plasma, and the packaged unit's ordering does not
  # fit UWSM's earlier compositor target. A Hyprland-specific unit below starts
  # in UWSM's later XDG-autostart phase instead. DMS Greeter remains disabled;
  # SDDM still owns login.
  programs.dms-shell = {
    enable = true;
    systemd.enable = false;

    # Keep the first DMS layer focused on the shell/control surfaces that are
    # being tested. Calendar and visualizer integrations can be added later in
    # separate, reviewable generations.
    enableAudioWavelength = false;
    enableCalendarEvents = false;
  };

  systemd.user.services.dms = {
    description = "Dank Material Shell (Hyprland UWSM session only)";
    after = [
      "wayland-session@hyprland.desktop.target"
      "graphical-session.target"
    ];
    partOf = [ "wayland-session@hyprland.desktop.target" ];
    wantedBy = [ "wayland-session-xdg-autostart@hyprland.desktop.target" ];
    restartIfChanged = true;
    # DMS launches several optional helpers by name. Give its service the same
    # declarative system path that contains dgop, matugen, NetworkManager,
    # wtype, and the normal session utilities installed by the module.
    path = [
      config.system.path
      # DMS launches desktop entries by their Exec name. Cursor is owned by
      # Home Manager, so expose the exact same pinned package to the DMS
      # service without promoting it to the global system package list.
      pkgs.code-cursor
      # Let DMS terminal actions and its health check resolve the already
      # proven Kitty package as well as Hyprland's absolute Kitty binding.
      pkgs.kitty
      # Thunderbird is a Home Manager package. Its desktop entry is indexed
      # by DMS, so expose the same executable to DMS's restricted service
      # path rather than relying on the user's interactive profile.
      pkgs.thunderbird
      # Discord follows the same Home Manager + DMS launcher boundary as
      # Thunderbird. Keep its executable explicit for Spotlight launches.
      pkgs.discord
    ];
    unitConfig = {
      ConditionEnvironment = "HYPRLAND_INSTANCE_SIGNATURE";
      Requisite = "wayland-session@hyprland.desktop.target";
    };
    serviceConfig = {
      Type = "dbus";
      BusName = "org.freedesktop.Notifications";
      ExecStart = "${pkgs.dms-shell}/bin/dms run --session";
      ExecReload = "${pkgs.procps}/bin/pkill -USR1 -x dms";
      Restart = "on-failure";
      RestartSec = 1.23;
      TimeoutStopSec = 10;
    };
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
    mesa-demos
    pciutils
    usbutils
    vulkan-tools
  ];

  system.stateVersion = "26.05";
}
