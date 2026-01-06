# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs,... }:

let
  unstable = import <unstable> { config.allowUnfree = true; };
  waydroid-script = pkgs.nur.repos.ataraxiasjel.waydroid-script;
in

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [ "i915.enable_guc=2" ];
  hardware.enableAllFirmware = true;

  swapDevices =[{
    device = "/var/lib/swapfile";
    size = 16 * 1024;
  }];

  networking.hostName = "xieshi"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    inter
    montserrat
    lato

  ];
  # Enable networking
  networking.networkmanager.enable = true;
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
      # onevpl-intel-gpu  # for newer GPUs on NixOS <= 24.05
      # https://github.com/intel/libvpl?tab=readme-ov-file#dispatcher-behavior-when-targeting-intel-gpus
      # skylake = KabyLake
      # intel-media-sdk # for older GPUs
    ];
  };
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
    # LIBVA_DRIVER_NAME = "nvidia";
  };

  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = [
    "modesetting" # example for Intel iGPU; use "amdgpu" here instead if your iGPU is AMD
    "nvidia"
  ];

  hardware.nvidia = {

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
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
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
    packages = with pkgs; [
      pkgs.home-manager
      #  thunderbird
      # vscode
    ];
  };
  # home-manager.backupFileExtension = "backup";
  # home-manager.users.jack =
  #   { pkgs, ... }:
  #   {
  #     home.packages = [
  #       pkgs.nixd
  #       pkgs.alejandra
  #       pkgs.lshw
  #       pkgs.nixfmt-rfc-style
  #       pkgs.discord
  #       pkgs.zoom-us
  #       pkgs.vlc
  #       pkgs.lmstudio
  #       pkgs.moonlight-qt
  #       pkgs.libreoffice
  #       pkgs.gimp
  #       pkgs.figma-linux
  #       pkgs.signal-desktop
  #       pkgs.xdotool
  #       pkgs.jq
  #       pkgs.youtube-music
  #       pkgs.spotify
  #       pkgs.libva-utils
  #       pkgs.godot_4
  #       pkgs.gpu-screen-recorder-gtk
  #       pkgs.mangohud
  #       pkgs.protonup-ng
  #       pkgs.lutris
  #       pkgs.bottles
  #       # pkgs.heroic
  #       # unstable.stremio
  #       pkgs.calibre
  #       pkgs.unciv
  #       pkgs.logseq
  #       pkgs.devenv
  #       # unstable._010editor
  #       # unstable.biome
  #       pkgs.cudaPackages.cuda_nvcc
  #       pkgs.endless-sky
  #       pkgs.freecad
  #       # pkgs.torrential
  #       pkgs.tesseract
  #       pkgs.imagemagickBig
  #       pkgs.poppler-utils
  #       # unstable.python313Packages.paddlepaddle
  #       # pkgs.python313Packages.paddleocr
  #       # unstable.python313Packages.paddlex
  #       # paddlex
  #       pkgs.ccache
  #       pkgs.google-chrome
  #       pkgs.youtube-tui
  #       pkgs.chawan
  #       pkgs.xournalpp
  #       # pkgs.phoronix-test-suite
  #       pkgs.geekbench
  #       # pkgs.intel-gpu-tools
  #       pkgs.nvtopPackages.full
  #       pkgs.lzip
  #       pkgs.retroarch-free
  #       pkgs.cachix
  #     ];
  #     dconf = {
  #       enable = true;
  #       settings = {
  #         "org/gnome/shell" = {
  #           disable-user-extensions = false; # enables user extensions
  #           enabled-extensions = [
  #             # Put UUIDs of extensions that you want to enable here.
  #             # If the extension you want to enable is packaged in nixpkgs,
  #             # you can easily get its UUID by accessing its extensionUuid
  #             # field (look at the following example).
  #             # pkgs.gnomeExtensions.blurt.extensionUuid
  #           ];
  #         };
  #       };
  #     };
  #     programs = {
  #       chromium.enable = true;
  #       obs-studio.enable = true;
  #       yt-dlp.enable = true;
  #       mpv.enable = true;
  #       neovim.enable = true;
  #       # retroarch = {
  #       #   enable = true;
  #       #   cores = {
  #       #     mupen64plus.enable = true;
  #       #   };
  #       # };
  #     };

  #     programs.zellij = {
  #       enable = true;
  #       # enableZshIntegration = true;
  #     };

  #     programs.mcfly = {
  #       enable = true;
  #       enableZshIntegration = true;
  #       fzf.enable = true;
  #     };

  #     nixpkgs.config.allowUnfree = true;
  #     programs.git = {
  #       enable = true;
  #       userName = "jack";
  #       userEmail = "ksio2124@protonmail.ch";
  #     };
  #     # programs.thefuck = {
  #     #   enable = true;
  #     #   enableZshIntegration = true;
  #     # };
  #     programs.texlive = {
  #       enable = true;
  #       extraPackages = tpkgs: {
  #         inherit (tpkgs) scheme-full;
  #       };
  #     };
  #     programs.direnv = {
  #       enable = true;
  #       enableZshIntegration = true; # Since you're using ZSH
  #       nix-direnv = {
  #         enable = true;
  #       };
  #     };
  #     programs.navi = {
  #       enable = true;
  #       enableZshIntegration = true; # Since you're using ZSH
  #     };
  #     programs.starship = {
  #       enable = true;
  #       enableZshIntegration = true; # Since you're using zsh
  #       settings = {
  #         # Example settings
  #         nix_shell = {
  #           symbol = "❄️ ";
  #           format = "via [$symbol$state( \($name\))]($style) ";
  #         };
  #         character = {
  #           success_symbol = "[➜](bold green)";
  #           error_symbol = "[✗](bold red)";
  #         };
  #       };
  #     };

  #     programs.zsh = {
  #       enable = true;
  #       autosuggestion.enable = true;
  #     };
  #     programs.fzf = {
  #       enable = true;
  #       enableZshIntegration = true; # Since you're using ZSH
  #     };
  #     programs.vscode = {
  #       enable = true;
  #       extensions = [
  #         pkgs.vscode-extensions.jnoortheen.nix-ide
  #         pkgs.vscode-extensions.github.copilot
  #         pkgs.vscode-extensions.github.copilot-chat
  #         pkgs.vscode-extensions.esbenp.prettier-vscode
  #         pkgs.vscode-extensions.dbaeumer.vscode-eslint
  #         pkgs.vscode-extensions.biomejs.biome
  #         pkgs.vscode-extensions.bradlc.vscode-tailwindcss
  #         pkgs.vscode-extensions.james-yu.latex-workshop
  #         pkgs.vscode-extensions.eamodio.gitlens
  #         pkgs.vscode-extensions.continue.continue
  #         pkgs.vscode-extensions.ritwickdey.liveserver
  #       ];
  #     };
  #     programs.firefox = {
  #       enable = true;
  #       profiles.default = {
  #         extensions = with nur.repos.rycee.firefox-addons; [
  #           ublock-origin
  #           bitwarden
  #           react-devtools
  #         ];
  #       };
  #     };

  #     programs.alacritty = {
  #       enable = true;
  #       settings = {
  #         font.normal.family = "FiraCode Nerd Font";
  #         window.opacity = 0.95;
  #       };
  #     };
  #     # The state version is required and should stay at the version you
  #     # originally installed.
  #     home.stateVersion = "25.05";
  #   };
  # # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # environment.systemPackages = with pkgs; [
  #   #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #   #  wget
  # ];
  environment.systemPackages = [
    pkgs.protonup-ng
    pkgs.mangohud
    waydroid-script
  ];

  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
  };
  programs.steam.enable = true;
  programs.gamemode.enable = true;
  programs.steam.gamescopeSession.enable = true;

  programs.zsh.enable = true;
  programs.adb.enable = true;

  virtualisation.waydroid.enable = true;
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
  system.stateVersion = "25.05"; # Did you read the comment?

}
