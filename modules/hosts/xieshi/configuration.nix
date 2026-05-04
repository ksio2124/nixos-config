{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.xieshi = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.hostXieshi
    ];
  };
  flake.nixosModules.hostXieshi = {
    config,
    pkgs,
    lib,
    ...
  }: let
    # waydroid-script = pkgs.nur.repos.ataraxiasjel.waydroid-script;
    wireplumber_0_5_12_pkgs = import (builtins.fetchTree {
      type = "github";
      owner = "nixos";
      repo = "nixpkgs";
      rev = "871b9fd269ff6246794583ce4ee1031e1da71895";
    }) {inherit (pkgs) system;};
    wireplumber_0_5_12 = wireplumber_0_5_12_pkgs.wireplumber;
  in {
    imports = [
      inputs.lanzaboote.nixosModules.lanzaboote
      inputs.nur.modules.nixos.default
      inputs.sops-nix.nixosModules.sops
      self.nixosModules.nix
    ];

    boot.loader.systemd-boot.enable = lib.mkForce false;

    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
    boot.loader.efi.canTouchEfiVariables = true;
    boot.kernelParams = ["i915.enable_guc=2"];
    hardware.enableAllFirmware = true;
    boot.kernel.sysctl = {
      "net.ipv4.ip_default_ttl" = 65; # Change 65 to your desired value
    };

    networking.hostName = "xieshi"; # Define your hostname.
    fonts.packages = with pkgs; [
      nerd-fonts.fira-code
      nerd-fonts.droid-sans-mono
      inter
      montserrat
      lato
    ];
    # Enable networking
    # networking.networkmanager.enable = true;
    hardware.sensor.iio.enable = true;

    # Set your time zone.
    time.timeZone = "America/New_York";

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

    # Enable the X11 windowing system.
    services.xserver.enable = true;

    # Enable the GNOME Desktop Environment.
    services.xserver.displayManager.gdm.enable = true;
    services.xserver.desktopManager.gnome.enable = true;

    # Configure keymap in X11
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    # Enable CUPS to print documents.
    services.printing.enable = true;
    services.printing.drivers = [
      pkgs.cnijfilter2
    ];

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-vaapi-driver
        intel-media-driver
        vpl-gpu-rt # for newer GPUs on NixOS >24.05 or unstable
      ];
    };
    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    # Load nvidia driver for Xorg and Wayland
    services.xserver.videoDrivers = [
      "modesetting" # example for Intel iGPU; use "amdgpu" here instead if your iGPU is AMD
      "nvidia"
    ];

    hardware.nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    hardware.nvidia.prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      # Make sure to use the correct Bus ID values for your system!
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:59:0:0";
      # amdgpuBusId = "PCI:54:0:0"; For AMD GPU
    };
    # Enable sound with pipewire.
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber = {
        enable = true;
        package = wireplumber_0_5_12;
      };
      # If you want to use JACK applications, uncomment this
      jack.enable = true;

      # use the example session manager (no others are packaged yet so this is enabled by default,
      # no need to redefine it in your config for now)
      #media-session.enable = true;
    };
    services.lact.enable = true;

    # Enable touchpad support (enabled default in most desktopManager).
    # services.xserver.libinput.enable = true;

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.jack = {
      isNormalUser = true;
      description = "jack";
      shell = pkgs.zsh;
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
      packages = with pkgs; [
        pkgs.home-manager
      ];
    };
    programs.firefox.enable = true;

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    # environment.systemPackages = with pkgs; [
    #   #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    #   #  wget
    # ];
    environment.systemPackages = [
      pkgs.neovim
      pkgs.impala
    ];

    environment.sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
    };
    programs.steam.enable = true;
    programs.gamemode.enable = true;
    programs.steam.gamescopeSession.enable = true;

    programs.zsh.enable = true;

    virtualisation.waydroid.enable = true;
    networking.firewall = rec {
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      allowedUDPPortRanges = allowedTCPPortRanges;
    };

    networking.useNetworkd = true;
    networking.networkmanager.enable = false;
    networking.wireless.iwd = {
      enable = true;
      settings = {
        Settings = {
          AutoConnect = true;
        };
      };
    };
    networking.wireless.enable = false;
    systemd.network.enable = true;
    systemd.network.wait-online.enable = false;

    sops.defaultSopsFile = ./secrets/config.yaml;
    sops.defaultSopsFormat = "yaml";
    sops.age.sshKeyPaths = ["/home/jack/.ssh/xieshi"];
    sops.age.keyFile = "/home/jack/.config/sops/age/keys.txt";
    sops.age.generateKey = true;
    # wireguard
    sops.secrets."wireguard/PrivateKey" = {
      mode = "640";
      owner = "systemd-network";
      group = "systemd-network";
    };
    systemd.network = {
      networks."50-wg0" = {
        matchConfig.Name = "wg0";

        address = [
          # /32 and /128 specifies a single address
          # for use on this wg peer machine
          "fd31:bf08:57cb::8/128"
          "192.168.2.2/24"
        ];
      };

      netdevs."50-wg0" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg0";
        };

        wireguardConfig = {
          ListenPort = 51820;
          PrivateKeyFile = config.sops.secrets."wireguard/PrivateKey".path;
          RouteTable = "main";
          FirewallMark = 42;
        };
        wireguardPeers = [
          {
            PublicKey = "fefPETytdUo2rwH0Ji2GYgtpx0ZUO3i4AtPIiyZYgUE=";
            AllowedIPs = [
              "fd31:bf08:57cb::7/128"
              "192.168.2.1/32"
            ];
            Endpoint = "cowgoesmoopiggoesoink.com:51820";
          }
        ];
      };
    };
    system.stateVersion = "25.05"; # Did you read the comment?
  };
}
