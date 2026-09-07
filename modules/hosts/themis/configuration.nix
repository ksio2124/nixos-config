{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.themis = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.hostThemis
    ];
  };
  flake.nixosModules.hostThemis = {
    config,
    pkgs,
    lib,
    ...
  }: let
    sunshinePkg = pkgs.sunshine.override {
      cudaSupport = true;
      cudaPackages = pkgs.cudaPackages_13;
    };
  in {
    imports = [
      inputs.lanzaboote.nixosModules.lanzaboote
      inputs.nur.modules.nixos.default
      inputs.sops-nix.nixosModules.sops
      inputs.disko.nixosModules.disko
      #self.nixosModules.disko
      self.nixosModules.nextcloud
      self.nixosModules.immich
      self.nixosModules.garage
      self.nixosModules.mosquitto
      #self.nixosModules.jellyfin
      self.nixosModules.postgresql
      self.nixosModules.anki-sync-server
      #self.nixosModules.wordpress
      #self.nixosModules.storjlabs_storagenode
      self.nixosModules.mailserver
      self.nixosModules.onlyoffice
      #self.nixosModules.firefox-syncserver
      # something not right might need a full restart of the computer
      self.nixosModules.nix
    ];
    sops.defaultSopsFile = ./secrets/config.yaml;
    sops.defaultSopsFormat = "yaml";
    sops.age.sshKeyPaths = ["/home/jack/.ssh/themis"];
    sops.age.keyFile = "/home/jack/.config/sops/age/keys.txt";
    sops.age.generateKey = true;
    boot.loader.efi.canTouchEfiVariables = true;
    # The EFI system partition is only 1G; without a limit, every switch
    # leaves another kernel+initrd on it until it fills up (as happened with
    # 113 accumulated generations). lanzaboote wraps systemd-boot, so this
    # option still applies.
    boot.loader.systemd-boot.configurationLimit = 10;
    boot.supportedFilesystems = {
      zfs = true;
    };
    boot.zfs.extraPools = ["mypool"];
    boot.zfs.forceImportRoot = false;
    boot.kernelParams = [
      "i915.enable_guc=2"
      # Dummy EDID on the Intel iGPU (card0) so it reports one output as
      # "connected" without a physical monitor attached — gives seat1's
      # compositor a real KMS display to scan out to.
      "drm.edid_firmware=HDMI-A-1:edid/virtual-display.bin"
      "video=HDMI-A-1:e"
    ];
    networking.hostName = "themis"; # Define your hostname.
    networking.hostId = "0e144610";
    powerManagement.powertop.enable = true;

    systemd.targets.sleep.enable = false;
    systemd.targets.suspend.enable = false;
    systemd.targets.hibernate.enable = false;
    systemd.targets.hybrid-sleep.enable = false;
    virtualisation.vmware.host.enable = true;

    # Set your time zone.
    time.timeZone = "America/Los_Angeles";

    # Select internationalisation properties.
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

    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = false;
      nvidiaSettings = true;

      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    };

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-ocl
        intel-media-driver
        intel-compute-runtime-legacy1
      ];
    };
    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
      VC_DISPLAY_DEVICE = "/dev/dri/renderD129";
      #LD_LIBRARY_PATH = "/run/opengl-driver/lib";
    }; # Optionally, set the environment variable

    # Enable the X11 windowing system.
    services.xserver.enable = true;
    boot.initrd.kernelModules = ["nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm"];
    # Enable the GNOME Desktop Environment.
    services.displayManager.gdm.enable = true;
    services.displayManager.gdm.autoSuspend = false;
    services.desktopManager.gnome.enable = true;
    services.displayManager.autoLogin = {
      enable = true;
      user = "jack";
    };

    # Workaround to prevent the GDM/Getty race condition on tty1
    systemd.services."getty@tty1".enable = false;
    systemd.services."autovt@tty1".enable = false;

    services.xserver.videoDrivers = [
      "modesetting" # example for Intel iGPU; use "amdgpu" here instead if your iGPU is AMD
      "nvidia"
    ];

    # Configure keymap in X11
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    # Enable CUPS to print documents.
    services.printing.enable = true;

    # Enable sound with pipewire.
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    environment.systemPackages = [];

    # Enable the OpenSSH daemon.
    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = true;
    };
    programs.steam.enable = true;
    programs.gamescope.enable = true;

    ##########################################################################
    # Primary seat's Sunshine instance.
    #
    # This previously ran as a dedicated system-level service using
    # `capture_method = kms` (with autologin off), so it could capture the
    # GDM greeter itself pre-login. In practice, Sunshine's KMS capture path
    # doing GL-based color conversion against this NVIDIA proprietary driver
    # is unreliable — every frame failed with GL_INVALID_OPERATION spam
    # (matches known upstream LizardByte/Sunshine issues on KMS+NVIDIA), so
    # streams were always black. Reverted to the proven design: autologin
    # back on, Sunshine as jack's own systemd user service via the nixpkgs
    # module, capture method left on auto (picks wlr/Wayland against jack's
    # real session) — this is what worked reliably for weeks before today.
    ##########################################################################
    services.sunshine = {
      enable = true;
      # autoStart wires `wantedBy = ["graphical-session.target"]` onto the
      # systemd *user* unit, which applies to every user's systemd instance
      # system-wide — not just jack's. That included gdm-greeter's own
      # seat1 greeter session, which was auto-starting a second copy of
      # this exact config and colliding on all its ports. Scoped the actual
      # enablement to jack only, in modules/home/jack@themis/home.nix.
      autoStart = false;
      capSysAdmin = true;
      openFirewall = false;
      settings = {
        encoder = "nvenc";
        # Now that seat1 gave card0 (Intel) a real connected+enabled
        # display too, Sunshine's KMS auto-detection for the primary
        # instance started picking card0 instead of card1 (NVIDIA) —
        # confirmed live via its capture log ("/dev/dri/card0 -> i915",
        # "Found connector ID [117]", the exact seat1 HDMI-A-1 connector).
        # NVENC then tried to import a DMA-BUF living on the *Intel* GPU,
        # a cross-GPU import that always fails ("Couldn't import RGB
        # Image: 0000300C" / EGL_BAD_PARAMETER, every frame, encoder stuck
        # recreating in a loop until the client gives up).
        #
        # Per LizardByte's own docs, adapter_name wants a *render node*
        # (e.g. /dev/dri/renderD128), not the control node — an earlier
        # attempt with "/dev/dri/card1" was silently ignored because of
        # this. renderD128 is confirmed (via /dev/dri/by-path) to be the
        # NVIDIA card (PCI 0000:01:00.0); renderD129 is the Intel iGPU.
        adapter_name = "/dev/dri/renderD128";
        # output_name wants a numeric id on Linux, not a connector-name
        # string (that's what tripped up seat1's own output_name attempt
        # earlier too) — 0 matches "Monitor 0 is DP-1" from Sunshine's own
        # KMS monitor list for this instance.
        output_name = "0";
        address_family = "both";
        lan_encryption_mode = 2;
        wan_encryption_mode = 2;
      };
      package = sunshinePkg;
    };

    hardware.uinput.enable = true;
    hardware.intel-gpu-tools.enable = true;
    hardware.firmware = [
      (pkgs.runCommand "custom-edid" {} ''
        mkdir -p $out/lib/firmware/edid
        cp ${./virtual-display.bin} $out/lib/firmware/edid/virtual-display.bin
      '')
    ];

    ##########################################################################
    # Real second logind seat ("seat1") bound to the idle Intel iGPU
    # (card0, PCI 0000:00:02.0). By default every device belongs to seat0;
    # this udev rule reassigns the Intel GPU (and its render node) to seat1
    # before systemd's built-in 73-seat-late.rules applies its seat0
    # fallback.
    #
    # NOT seat-tagging Sunshine's own uinput virtual keyboard/mouse here
    # (tried it, reverted): those devices are unparented (`/sys/devices/
    # virtual/input/...`), so udev's own seat rules have no PCI/USB parent
    # to inherit a seat from — and both the primary and seat1 Sunshine
    # instances create devices with the exact same hardcoded name
    # ("Sunshine Mouse"/"Sunshine Keyboard"), so a static ATTRS{name} match
    # can't tell them apart. Tagging by name previously mis-tagged jack's
    # own primary-seat0 input devices as seat1, breaking his real mouse/
    # keyboard. Left at the systemd/logind default (untagged -> seat0),
    # which is correct for the primary seat; seat1 getting remote input
    # through its own Sunshine instance is a separate, still-open problem.
    ##########################################################################
    # Sunshine's kmsgrab has no working config knob to pin which
    # /dev/dri/cardN it captures from — confirmed live with both wrong and
    # doc-correct formats of adapter_name/output_name (LizardByte docs:
    # adapter_name wants a render node e.g. /dev/dri/renderD128,
    # output_name wants a numeric id on Linux): it always grabbed card0
    # (Intel, seat1's dummy-EDID output) instead of card1 (NVIDIA, jack's
    # real monitors), regardless. NVENC then failed importing a DMA-BUF
    # from the wrong GPU on every frame ("Couldn't import RGB Image:
    # 0000300C" / EGL_BAD_PARAMETER; the binary even ships the string
    # "Using NVENC with your display connected to a different GPU may not
    # work properly!" — a known, apparently unfixed-via-config limitation
    # in this build). Blocking it at the permission level instead: card0's
    # default GROUP="video"/"render" static permissions (how jack's
    # non-session, non-logind-mediated Sunshine process gets raw access to
    # it) are overridden to a dedicated group that only seat1-sunshine is
    # in — jack is not. This doesn't affect GDM's own seat1 greeter
    # session, which acquires DRM master through logind's root-mediated
    # TakeDevice() call, not raw file permissions.
    users.groups.seat1-gpu = {};

    services.udev.extraRules = ''
      SUBSYSTEM=="drm", KERNELS=="0000:00:02.0", ENV{ID_SEAT}="seat1", TAG+="seat", TAG+="uaccess", GROUP="seat1-gpu", MODE="0660"
    '';

    # GDM's greeter (used on both seat0, where it's hidden behind jack's
    # autologin, and seat1, where it's the real login screen) idle-blanks
    # its screen with no physical input to keep it awake — confirmed live:
    # seat1's HDMI-A-1 CRTC went from "enabled" to "disabled" ~5 minutes
    # after GDM spawned the greeter, at which point sunshine-seat1's KMS
    # capture could no longer find any monitor on card0 at all. Disable
    # blanking for the shared "gdm" dconf profile so seat1's greeter stays
    # rendering while nobody's connected yet to inject remote input.
    # `/etc/dconf/db` is owned entirely by the `programs.dconf` module (a
    # single compiled derivation) — can't drop plain environment.etc files
    # under it directly, has to go through profiles.<name>.databases.
    programs.dconf.profiles.gdm.databases = [
      {
        settings = {
          "org/gnome/desktop/session" = {
            idle-delay = lib.gvariant.mkUint32 0;
          };
          "org/gnome/settings-daemon/plugins/power" = {
            sleep-inactive-ac-timeout = lib.gvariant.mkInt32 0;
            sleep-inactive-ac-type = "nothing";
          };
        };
      }
    ];

    # Normal desktop-login account for someone else to use at the physical
    # console (GDM will list it alongside jack). No password is set here —
    # run `sudo passwd guest` on themis after switching so it never ends up
    # committed to git.
    users.users.guest = {
      isNormalUser = true;
      description = "guest";
      extraGroups = ["networkmanager"];
    };

    ##########################################################################
    # seat1: a real second systemd-logind seat bound to the idle Intel iGPU
    # (see the udev rules above). Turns out GDM itself is genuinely
    # multiseat-aware: the moment logind announces a new seat, GDM
    # automatically spawns its own greeter (gnome-shell/mutter, real DRM
    # master, real login prompt) on it — confirmed live: `loginctl
    # session-status` showed a `class=greeter` GDM session on seat1
    # immediately after the udev rule created it, with `autoLogin` correctly
    # *not* applying there (autoLogin only targets jack's seat0 session). A
    # hand-rolled greetd/tuigreet login was tried first and fought GDM for
    # DRM master on card0 — dropped in favor of just letting GDM own seat1,
    # same as seat0. Captures via KMS (driver-level, not a compositor
    # protocol), so it doesn't care whether the session on seat1 is GDM's
    # greeter or a full GNOME session. Encoding uses Intel Quick Sync (VAAPI
    # via renderD129), so this whole seat never touches the NVIDIA GPU.
    ##########################################################################
    users.users.seat1-sunshine = {
      isNormalUser = true;
      group = "seat1-sunshine";
      # "uinput" is required to open /dev/uinput at all — without it,
      # Sunshine logs "Unable to create virtual mouse/keyboard: Permission
      # denied" and remote input silently does nothing. "seat1-gpu" is the
      # only group allowed to open card0 now (see the udev rule above) —
      # jack is deliberately not in it.
      extraGroups = ["video" "render" "uinput" "seat1-gpu"];
    };
    users.groups.seat1-sunshine = {};

    environment.etc."sunshine-seat1/sunshine.conf".text = ''
      # +100 offset from primary's default base (47989) so seat1's whole
      # derived port range (pairing/http/webUI/video/control/audio/mic/
      # rtsp, each an offset from this base) stays cleanly disjoint from
      # primary's, regardless of what either side's exact offsets are.
      port = 48099
      min_log_level = debug
      encoder = vaapi
      address_family = both
      lan_encryption_mode = 2
      wan_encryption_mode = 2
    '';

    systemd.services."sunshine-seat1" = {
      description = "Second Sunshine streaming instance (seat1, Intel iGPU)";
      wantedBy = ["multi-user.target"];
      after = ["display-manager.service"];
      requires = ["display-manager.service"];
      serviceConfig = {
        User = "seat1-sunshine";
        Type = "simple";
        Restart = "on-failure";
        RestartSec = 2;
        # KMS capture reads DRM directly (no compositor socket to wait on),
        # so just give GDM's seat1 greeter a moment to actually mode-set
        # HDMI-A-1 after it spawns.
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
        ExecStart = "${pkgs.sunshine}/bin/sunshine /etc/sunshine-seat1/sunshine.conf";
        AmbientCapabilities = ["CAP_SYS_ADMIN"];
        CapabilityBoundingSet = ["CAP_SYS_ADMIN"];
      };
    };

    system.stateVersion = "25.05"; # Did you read the comment?
  };
}
