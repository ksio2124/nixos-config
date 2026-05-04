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
      self.nixosModules.nextcloud
      self.nixosModules.anki-sync-server
      self.nixosModules.wordpress
      self.nixosModules.storjlabs_storagenode
      self.nixosModules.mailserver2
      #self.nixosModules.onlyoffice
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
    boot.supportedFilesystems = {
      zfs = true;
    };
    boot.zfs.extraPools = ["mypool"];
    boot.kernelParams = ["i915.enable_guc=2"];
    networking.hostName = "themis"; # Define your hostname.
    networking.hostId = "0e144610";
    powerManagement.powertop.enable = true;

    systemd.targets.sleep.enable = false;
    systemd.targets.suspend.enable = false;
    systemd.targets.hibernate.enable = false;
    systemd.targets.hybrid-sleep.enable = false;

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

      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        vpl-gpu-rt
        intel-media-driver # For Broadwell (2014) or newer processors. LIBVA_DRIVER_NAME=iHD
        # intel-vaapi-driver # For older processors. LIBVA_DRIVER_NAME=i965
      ];
    };
    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
    }; # Optionally, set the environment variable

    # Enable the X11 windowing system.
    services.xserver.enable = true;

    # Enable the GNOME Desktop Environment.
    services.xserver.displayManager.gdm.enable = true;
    services.xserver.desktopManager.gnome.enable = true;

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

    environment.systemPackages = with pkgs; [
    ];

    # Enable the OpenSSH daemon.
    services.openssh = {
      enable = true;
      passwordAuthentication = true;
    };

    system.stateVersion = "25.05"; # Did you read the comment?
  };
}
