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
    ...
  }: {
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
      self.nixosModules.headscale
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
      self.nixosModules.cuda
    ];
    # Passwordless sudo for jack, scoped to read-only diagnostics
    # (host/container service logs and status, including `-M <machine>`)
    # so these can be run non-interactively (e.g. by Claude Code) without
    # exposing anything that mutates system or container state. Deliberately
    # excludes `machinectl shell`/`login`, which grant an arbitrary root
    # shell inside a container.
    security.sudo.extraRules = [
      {
        users = ["jack"];
        commands = [
          {
            command = "${pkgs.systemd}/bin/journalctl *";
            options = ["NOPASSWD"];
          }
          {
            command = "${pkgs.systemd}/bin/systemctl status *";
            options = ["NOPASSWD"];
          }
          {
            command = "${pkgs.systemd}/bin/machinectl status *";
            options = ["NOPASSWD"];
          }
          {
            command = "${pkgs.systemd}/bin/machinectl list";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];

    sops.defaultSopsFile = ./secrets/config.yaml;
    sops.defaultSopsFormat = "yaml";
    sops.age.sshKeyPaths = ["/home/jack/.ssh/themis"];
    sops.age.keyFile = "/home/jack/.config/sops/age/keys.txt";
    sops.age.generateKey = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.supportedFilesystems = {
      zfs = true;
    };
    boot.zfs.extraPools = ["mypool"];
    boot.zfs.forceImportRoot = false;
    boot.kernelParams = [
      "i915.enable_guc=2"
      # "drm.edid_firmware=DP-1:edid/virtual-display.bin"
      # "video=DP-1:e"
    ];
    networking.hostName = "themis"; # Define your hostname.
    networking.hostId = "0e144610";
    boot.binfmt.emulatedSystems = ["aarch64-linux"];
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
      user = "jack"; # Change this to your actual username
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

    # Tailscale client, pointed at our own headscale instance, set up as an
    # exit node. authKeyFile auto-starts+authenticates it on boot; the
    # preauth key itself is generated via `headscale preauthkeys create`
    # (see modules/services/headscale.nix) and stored in sops.
    sops.secrets."tailscale/authKey" = {};
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "server";
      port = 41641;
      authKeyFile = config.sops.secrets."tailscale/authKey".path;
      extraUpFlags = [
        "--login-server=https://headscale.ksio2124.com"
        "--advertise-exit-node"
      ];
    };
    programs.steam.enable = true;
    programs.gamescope.enable = true;
    # 2. Declarative Sunshine Configuration
    services.sunshine = {
      enable = true;
      autoStart = true;
      capSysAdmin = true; # Necessary for capture
      openFirewall = false;
      settings = {
        # Force Sunshine to use Wayland/wlr capture
        #capture_method = "wlr";
        # Define the encoder (nvenc for NVIDIA, vaapi for AMD/Intel)
        encoder = "nvenc";
        address_family = "both";
        lan_encryption_mode = 2;
        wan_encryption_mode = 2;
        # adapter_name = "/dev/dri/renderD129";
      };
    };
    # systemd.user.services.sunshine.serviceConfig.Environment = [
    #   "LD_LIBRARY_PATH=/run/opengl-driver/lib:/run/opengl-driver-32/lib"
    #   "VC_DISPLAY_DEVICE=/dev/dri/renderD129"
    #
    #   # You can add more variables here if needed:
    #   # "MY_VAR=value"
    # ];

    hardware.uinput.enable = true;
    hardware.intel-gpu-tools.enable = true;
    # hardware.firmware = [
    #   (pkgs.runCommand "custom-edid" {} ''
    #     mkdir -p $out/lib/firmware/edid
    #     cp ${./virtual-display.bin} $out/lib/firmware/edid/virtual-display.bin
    #   '')
    # ];

    system.stateVersion = "25.05"; # Did you read the comment?
  };
}
