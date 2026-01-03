# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  lib,
  ...
}:
let
  nur = import <nur> { inherit pkgs; };
  unstable = import <unstable> { config.allowUnfree = true; };
  # test = import (builtins.fetchGit {
  #   # Descriptive name to make the store path easier to identify
  #   name = "my-old-revision";
  #   url = "https://github.com/NixOS/nixpkgs/";
  #   ref = "refs/heads/nixpkgs-unstable";
  #   rev = "045304ae9a405c86a8960e5c12d7a0755313ec44";
  # }) { };

  # paddlex = test.python313Packages.paddlex;
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    <home-manager/nixos>
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  nix = {
    package = pkgs.nix;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings.trusted-users = [
      "root"
      "jack"
    ];
    binaryCaches = [
      "https://nix-community.cachix.org"
    ];
    binaryCachePublicKeys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];

  };

  boot.initrd.luks.devices."luks-9a454225-8859-4c36-b62b-b000a7626a55".device =
    "/dev/disk/by-uuid/9a454225-8859-4c36-b62b-b000a7626a55";
  networking.hostName = "prime"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
  networking.wg-quick.interfaces = {
    # "wg0" is the network interface name. You can name the interface arbitrarily.
    wg2 = {
      # Determines the IP address and subnet of the client's end of the tunnel interface.
      address = [ "10.10.10.6/32" ];
      # listenPort = 51820; # to match firewall allowedUDPPorts (without this wg uses random port numbers)

      # Path to the private key file.
      #
      # Note: The private key can also be included inline via the privateKey option,
      # but this makes the private key world-readable; thus, using privateKeyFile is
      # recommended.
      privateKey = "CJpTAnrd3s8G0ayU8aahQgpn1LLke7MkRn0oOJYsqkA=";

      peers = [
        # For a client configuration, one peer entry for the server will suffice.

        {
          # Public key of the server (not a file path).
          publicKey = "Fp4s9HVBVZKn9bNty8fBhd/MoctVtCFpWbu0TlaA3jc=";

          # Forward all the traffic via VPN.
          allowedIPs = [
            "0.0.0.0/0"
            "::/0"
            "192.168.1.0/24"
          ];
          # Or forward only particular subnets
          #allowedIPs = [ "10.100.0.1" "91.108.12.0/22" ];

          # Set this to the server IP and port.
          endpoint = "cowgoesmoopiggoesoink.com:51820"; # ToDo: route to endpoint not automatically configured https://wiki.archlinux.org/index.php/WireGuard#Loop_routing https://discourse.nixos.org/t/solved-minimal-firewall-setup-for-wireguard-client/7577

          # Send keepalives every 25 seconds. Important to keep NAT tables alive.
          persistentKeepalive = 25;
        }
      ];
    };
  };

  fonts.packages = with pkgs; [
    # (nerdfonts.override {
    #   fonts = [
    #     "FiraCode"
    #     "DroidSansMono"
    #   ];
    # })
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    inter
    montserrat
    lato

  ];
  # Enable
  networking.networkmanager.enable = true;

  # Set your time zone.
  # time.timeZone = "America/Los_Angeles";
  time.timeZone = lib.mkDefault null;
  services.automatic-timezoned.enable = true;
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

  # services.sunshine = {
  #   enable = true;
  #   # Enable nvenc support
  #   package =
  #     with pkgs;
  #     (pkgs.sunshine.override {
  #       cudaSupport = true;
  #       cudaPackages = cudaPackages;
  #     }).overrideAttrs
  #       (old: {
  #         nativeBuildInputs = old.nativeBuildInputs ++ [
  #           cudaPackages.cuda_nvcc
  #           (lib.getDev cudaPackages.cuda_cudart)
  #         ];
  #         cmakeFlags = old.cmakeFlags ++ [
  #           "-DCMAKE_CUDA_COMPILER=${(lib.getExe cudaPackages.cuda_nvcc)}"
  #         ];
  #       });
  #   openFirewall = true;
  #   capSysAdmin = true;
  # };
  services.ollama = {
    enable = true;
    package = unstable.ollama;
    acceleration = "cuda";
  };
  services.udev.packages = [
    pkgs.android-udev-rules
  ];

  services.tftpd.enable = true;
  # services.open-webui.enable = true;
  services.flatpak.enable = true;
  hardware.xpadneo.enable = true; # Enable the xpadneo driver for Xbox One wireless controllers
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General = {
      experimental = true; # show battery

      # https://www.reddit.com/r/NixOS/comments/1ch5d2p/comment/lkbabax/
      # for pairing bluetooth controller
      Privacy = "device";
      JustWorksRepairing = "always";
      Class = "0x000100";
      FastConnectable = true;
    };
  };
  services.blueman.enable = true;

  boot = {
    extraModulePackages = with config.boot.kernelPackages; [ xpadneo ];
    extraModprobeConfig = ''
      options bluetooth disable_ertm=Y
    '';
    # connect xbox controller
  };
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      # your Open GL, Vulkan and VAAPI drivers
      vpl-gpu-rt # for newer GPUs on NixOS >24.05 or unstable
      libvdpau-va-gl
      intel-media-driver
      nvidia-vaapi-driver
      # intel-vaapi-driver
    ];
  };
  environment.sessionVariables = {
    # LIBVA_DRIVER_NAME = "iHD";
    NVD_BACKEND = "direct";
    LIBVA_DRIVER_NAME = "nvidia";
  }; # Force intel-media-driver

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [     "modesetting"  # example for Intel iGPU; use "amdgpu" here instead if your iGPU is AMD
    "nvidia" ];
  hardware.system76.enableAll = true;
  hardware.nvidia = {
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      # sync.enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };

    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the bare essentials.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = true;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.displayManager.defaultSession = "gnome";
  services.power-profiles-daemon.enable = false;

  # Configure keymap in X11
  services.xserver = {
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

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
    packages = [
    ];
  };

  home-manager.backupFileExtension = "backup";
  home-manager.users.jack =
    { pkgs, ... }:
    # let
    #   home-manager-unstable = import <home-manager-unstable/nixos> { inherit pkgs; };
    # in
    {
      home.packages = [
        pkgs.nixd
        pkgs.alejandra
        pkgs.lshw
        pkgs.nixfmt-rfc-style
        pkgs.discord
        pkgs.zoom-us
        pkgs.vlc
        unstable.lmstudio
        pkgs.moonlight-qt
        pkgs.libreoffice
        pkgs.gimp
        pkgs.figma-linux
        pkgs.signal-desktop
        pkgs.xdotool
        pkgs.jq
        pkgs.youtube-music
        pkgs.spotify
        pkgs.libva-utils
        pkgs.godot_4
        pkgs.gpu-screen-recorder-gtk
        pkgs.mangohud
        pkgs.protonup
        pkgs.lutris
        pkgs.bottles
        # pkgs.heroic
        pkgs.stremio
        pkgs.calibre
        unstable.unciv
        unstable.logseq
        unstable.devenv
        # unstable._010editor
        # unstable.biome
        pkgs.cudaPackages.cuda_nvcc
        pkgs.endless-sky
        pkgs.freecad
        pkgs.torrential
        pkgs.tesseract
        pkgs.imagemagickBig
        pkgs.poppler-utils
        # unstable.python313Packages.paddlepaddle
        # pkgs.python313Packages.paddleocr
        # unstable.python313Packages.paddlex
        # paddlex
        pkgs.ccache
        pkgs.google-chrome
      ];
      # https://github.com/vimjoyer/nixos-gaming-video
      home.sessionVariables = {
        STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
      };
      dconf = {
        enable = true;
        settings = {
          "org/gnome/shell" = {
            disable-user-extensions = false; # enables user extensions
            enabled-extensions = [
              # Put UUIDs of extensions that you want to enable here.
              # If the extension you want to enable is packaged in nixpkgs,
              # you can easily get its UUID by accessing its extensionUuid
              # field (look at the following example).
              # pkgs.gnomeExtensions.blurt.extensionUuid
            ];
          };
        };
      };
      programs = {
        chromium.enable = true;
        obs-studio.enable = true;
        yt-dlp.enable = true;
      };

      programs.zellij = {
        enable = true;
        # enableZshIntegration = true;
      };

      programs.mcfly = {
        enable = true;
        enableZshIntegration = true;
        fzf.enable = true;
      };

      nixpkgs.config.allowUnfree = true;
      programs.git = {
        enable = true;
        userName = "jack";
        userEmail = "ksio2124@protonmail.ch";
      };
      programs.thefuck = {
        enable = true;
        enableZshIntegration = true;
      };
      programs.texlive = {
        enable = true;
        extraPackages = tpkgs: {
          inherit (tpkgs) scheme-full;
        };
      };
      programs.direnv = {
        enable = true;
        enableZshIntegration = true; # Since you're using ZSH
        nix-direnv = {
          enable = true;
        };
      };
      programs.navi = {
        enable = true;
        enableZshIntegration = true; # Since you're using ZSH
      };
      programs.starship = {
        enable = true;
        enableZshIntegration = true; # Since you're using zsh
        settings = {
          # Example settings
          nix_shell = {
            symbol = "❄️ ";
            format = "via [$symbol$state( \($name\))]($style) ";
          };
          character = {
            success_symbol = "[➜](bold green)";
            error_symbol = "[✗](bold red)";
          };
        };
      };

      programs.zsh = {
        enable = true;
        autosuggestion.enable = true;
      };
      programs.fzf = {
        enable = true;
        enableZshIntegration = true; # Since you're using ZSH
      };
      programs.vscode = {
        enable = true;
        extensions = [
          pkgs.vscode-extensions.jnoortheen.nix-ide
          pkgs.vscode-extensions.github.copilot
          pkgs.vscode-extensions.github.copilot-chat
          pkgs.vscode-extensions.esbenp.prettier-vscode
          pkgs.vscode-extensions.dbaeumer.vscode-eslint
          pkgs.vscode-extensions.biomejs.biome
          pkgs.vscode-extensions.bradlc.vscode-tailwindcss
          pkgs.vscode-extensions.james-yu.latex-workshop
          pkgs.vscode-extensions.eamodio.gitlens
          pkgs.vscode-extensions.continue.continue
          pkgs.vscode-extensions.ritwickdey.liveserver
        ];
      };
      programs.firefox = {
        enable = true;
        profiles.default = {
          extensions = with nur.repos.rycee.firefox-addons; [
            ublock-origin
            bitwarden
            react-devtools
          ];
        };
      };

      programs.alacritty = {
        enable = true;
        settings = {
          font.normal.family = "FiraCode Nerd Font";
          window.opacity = 0.95;
        };
      };
      # The state version is required and should stay at the version you
      # originally installed.
      home.stateVersion = "24.05";
    };
  # Install firefox.
  # programs.firefox.enable = true;
  programs.immersed.enable = true;
  programs.zsh.enable = true;
  programs.adb.enable = true;
  programs.alvr.enable = true;
  # https://medium.com/@notquitethereyet_/gaming-on-nixos-%EF%B8%8F-f98506351a24
  programs.steam.enable = true;
  programs.steam.gamescopeSession.enable = true;
  programs.gamemode.enable = true;
  programs.gpu-screen-recorder.enable = true;

  programs.virt-manager.enable = true;

  users.groups.libvirtd.members = [ "jack" ];

  virtualisation.libvirtd.enable = true;
  virtualisation.docker.enable = true;

  virtualisation.spiceUSBRedirection.enable = true;
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.cudaSupport = true;
  nixpkgs.config.allowUnfreePredicate = _: true;
  programs.git = {
    enable = true;
  };
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    xclip
    hwinfo
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}
