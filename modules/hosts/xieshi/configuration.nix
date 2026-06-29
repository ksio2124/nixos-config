{
  inputs,
  self,
  ...
}: {
  # flake.overlays.default = final: prev: {
  #   tetrd = prev.tetrd.overrideAttrs (old: {
  #     src = prev.fetchurl {
  #       url = "https://download.tetrd.app/files/tetrd.linux_amd64.pkg.tar.xz";
  #       hash = "sha256-hn3p+iUF7JYQ+TFGbJqvqwDvzgoCfc5SduBgtAExHS0=";
  #     };
  #   });
  # };
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
      "net.ipv6.conf.all.hop_limit" = 65;
      "net.ipv6.conf.default.hop_limit" = 65;
    };

    networking.hostName = "xieshi"; # Define your hostname.
    hardware.sensor.iio.enable = true;

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
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
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
      jack.enable = true;
    };
    services.lact.enable = true;

    environment.systemPackages = [
      pkgs.impala
    ];

    environment.sessionVariables = {
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
    };
    programs.steam.enable = true;
    programs.gamemode.enable = true;
    programs.steam.gamescopeSession.enable = true;

    virtualisation.waydroid.enable = true;
    virtualisation.spiceUSBRedirection.enable = true;
    networking.firewall = rec {
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      allowedUDPPortRanges = allowedTCPPortRanges;
    };

    networking = {
      nameservers = ["1.1.1.1" "8.8.8.8"];
    };

    networking.useNetworkd = true;
    networking.networkmanager.enable = false;
    networking.wireless.iwd = {
      enable = true;
      settings = {
        Rank = {
          BandModifier2_4GHz = 0.1;
        };
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
      owner = "systemd-network";
      group = "systemd-network";
    };
    # 1. Enable the Avahi daemon
    services.avahi = {
      enable = true;

      # Allow Avahi to find other devices (Client mode)
      # nssmdns4 = true; # Resolves IPv4 addresses
      nssmdns6 = true; # Resolves IPv6 addresses

      # # Automatically advertise this computer's hostname to the network
      # publish = {
      #   enable = true;
      #   addresses = true; # Broadcasts this machine's IP addresses
      #   userServices = true; # Broadcasts local services if you configure them
      # };
    };
    # services.tetrd.enable = true;
    # environment.etc."resolv.conf" = {
    #   source = lib.mkForce "/run/systemd/resolve/stub-resolv.conf";
    # };
    # services.resolved.enable = false;

    # 2. Open the Firewall for mDNS traffic
    networking.firewall.allowedUDPPorts = [5353];
    networking.firewall.checkReversePath = false;
    networking.firewall.extraCommands = ''
      iptables -t mangle -A POSTROUTING -o usb0 -j TTL --ttl-set 65
      ip6tables -t mangle -A POSTROUTING -o usb0 -j HL --hl-set 65
    '';
    # sops.secrets."protonvpn/PrivateKey" = {
    #   owner = "systemd-network";
    #   group = "systemd-network";
    # };
    # systemd.network.netdevs."50-xieshi" = {
    #   netdevConfig = {
    #     Kind = "wireguard";
    #     Name = "xieshi";
    #   };
    #
    #   wireguardConfig = {
    #     PrivateKeyFile = config.sops.secrets."protonvpn/PrivateKey".path;
    #     RouteTable = "main";
    #     FirewallMark = 42;
    #   };
    #
    #   wireguardPeers = [
    #     {
    #       PublicKey = "1Fe25chEMe3i5ODyDeHhC94UY63O4vAyMw1KDgxcAk8=";
    #       AllowedIPs = ["0.0.0.0/0" "::/0"];
    #       Endpoint = "149.40.62.26:51820";
    #       PersistentKeepalive = 25;
    #     }
    #   ];
    # };
    #
    # systemd.network.networks."50-xieshi" = {
    #   matchConfig.Name = "xieshi";
    #
    #   address = [
    #     "10.2.0.2/32"
    #   ];
    #
    #   dns = ["10.2.0.1"];
    #
    #   networkConfig = {
    #     DNSDefaultRoute = true;
    #   };
    # };
    # systemd.network = {
    #   networks."50-wg0" = {
    #     matchConfig.Name = "wg0";
    #
    #     address = [
    #       # /32 and /128 specifies a single address
    #       # for use on this wg peer machine
    #       "fd31:bf08:57cb::8/128"
    #       "192.168.2.2/24"
    #     ];
    #   };
    #
    #   netdevs."50-wg0" = {
    #     netdevConfig = {
    #       Kind = "wireguard";
    #       Name = "wg0";
    #     };
    #
    #     wireguardConfig = {
    #       ListenPort = 51820;
    #       PrivateKeyFile = config.sops.secrets."wireguard/PrivateKey".path;
    #       RouteTable = "main";
    #       FirewallMark = 42;
    #     };
    #     wireguardPeers = [
    #       {
    #         PublicKey = "fefPETytdUo2rwH0Ji2GYgtpx0ZUO3i4AtPIiyZYgUE=";
    #         AllowedIPs = [
    #           "fd31:bf08:57cb::7/128"
    #           "192.168.2.1/32"
    #         ];
    #         PersistentKeepalive = 25;
    #         Endpoint = "ksio2124.com:51820";
    #       }
    #     ];
    #   };
    # };
    system.stateVersion = "25.05"; # Did you read the comment?
  };
}
