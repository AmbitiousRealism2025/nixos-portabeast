{
  config,
  helium,
  lib,
  nvidiaPkgs,
  opencode,
  pkgs,
  t3code,
  traycer,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./browser.nix
    ./flatpak.nix
    ./nemo-preview-integration.nix
    ./onepassword.nix
    ./storage-integration.nix
    ./swiftpoint-x1.nix
  ];

  # Preserve the working Calamares bootloader configuration.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # systemd 260 records the selected swapfile device and physical offset in
  # the UEFI HibernateLocation variable. Its initrd generator consumes that
  # variable on the next boot and resumes before mounting the real root.
  boot.initrd.systemd.enable = true;

  # Keep the release-pinned userspace, but use the matching Linux 7.1.6 and
  # NVIDIA 595.84 pair from the narrowly pinned driver source. NVIDIA 595.84
  # specifically fixes RTD3 suspend/resume failures seen on this laptop.
  boot.kernelPackages = nvidiaPkgs.linuxPackages_latest;

  # Keep fast compressed RAM swap for normal pressure. The lower-priority
  # ext4 swapfile is large enough for 32 GiB RAM and exists primarily as the
  # durable hibernation target; systemd deliberately ignores zram when
  # selecting a hibernation device.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };
  swapDevices = [
    {
      device = "/swapfile";
      size = 40960;
      priority = 10;
    }
  ];

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  # Run Tailscale as an ordinary authenticated node. Open its WireGuard UDP
  # listener for more reliable direct peer connections, but do not enable
  # subnet-router or exit-node routing features on this workstation.
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "none";
  };

  # The CachyOS-matched NVIDIA 610 open stack has passed manual s2idle and
  # post-resume application tests. Extend that verified path to lid close on
  # battery and external power. A docked/external-display setup still ignores
  # lid close, and the untested hibernation paths remain disabled below.
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
  };

  systemd.sleep.settings.Sleep = {
    # Use s2idle and manual hibernation with the open 610 driver stack. Keep
    # hybrid sleep and suspend-then-hibernate disabled until manual hibernate
    # has independently passed.
    AllowSuspend = "yes";
    AllowHibernation = "yes";
    AllowHybridSleep = "no";
    AllowSuspendThenHibernate = "no";
    MemorySleepMode = "s2idle";
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
    # Match the working CachyOS stack: NVIDIA 610 open kernel module, GSP,
    # kernel suspend notifiers, full VRAM preservation, and no forced RTD3.
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    open = true;
    gsp.enable = true;
    moduleParams.nvidia.NVreg_TemporaryFilePath = "/var/tmp";
    modesetting.enable = true;
    powerManagement = {
      enable = true;
      kernelSuspendNotifier = true;
      finegrained = false;
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
      # Meld is the only graphical application in the utility batch; expose
      # it so DMS Spotlight can launch its desktop entry reliably.
      pkgs.meld
      # The package is a pinned upstream AppImage; DMS needs its executable
      # path explicitly because it does not inherit Home Manager's profile.
      opencode.desktop
      # Helium is an alternative browser only. Its explicit DMS path makes the
      # reviewed launcher work without changing Zen's MIME ownership.
      helium
      # T3 Code uses the existing declarative Codex CLI path inherited above;
      # this entry merely makes the sandboxed desktop wrapper launchable.
      t3code
      traycer
      # These applications remain Home Manager-owned. Their upstream desktop
      # entries use bare executable names, so make those names resolvable from
      # DMS's intentionally restricted service environment.
      pkgs.easyeffects
      pkgs.obsidian
      pkgs.moonlight-qt
      # Zed is Home Manager-owned, while DMS runs with a deliberately narrow
      # service path. Expose the same package so its desktop entry launches.
      pkgs.zed-editor
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
  # This stationary, unencrypted home system prioritizes convenient local
  # authentication. This affects only future password changes through passwd;
  # password hashing remains yescrypt.
  security.pam.services.passwd.rules.password.unix.settings.minlen = 4;
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
