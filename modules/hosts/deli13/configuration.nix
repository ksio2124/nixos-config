{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.deli13 = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.hostDeli13
    ];
  };

  flake.nixosModules.hostDeli13 = {
    pkgs,
    lib,
    ...
  }: {
    imports = [
      inputs.lanzaboote.nixosModules.lanzaboote
      self.nixosModules.nix
    ];

    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };

    # Cache swapped pages compressed in RAM before using the encrypted swap file.
    boot.zswap.enable = true;

    hardware.enableAllFirmware = true;
    hardware.intel-gpu-tools.enable = true;
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    networking.hostName = "deli13";
    networking.networkmanager.enable = true;

    services.udev.extraRules = ''
      ACTION=="add|change", SUBSYSTEM=="input", KERNEL=="event*", ATTRS{name}=="ELAN24F0:00 04F3:24F0", ENV{LIBINPUT_IGNORE_DEVICE}="1"
    '';

    time.timeZone = "America/Los_Angeles";
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
    services.xserver.videoDrivers = ["modesetting"];
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    services.printing.enable = true;

    # Intel UHD 620: Mesa supplies OpenGL and Vulkan, including
    # the 32-bit drivers needed by Steam; iHD provides VA-API video acceleration.
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = [pkgs.intel-media-driver];
      extraPackages32 = [pkgs.pkgsi686Linux.intel-media-driver];
    };
    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
      STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
    };

    programs.steam.enable = true;
    programs.gamemode.enable = true;
    programs.steam.gamescopeSession.enable = true;

    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    programs.git.enable = true;

    environment.systemPackages = with pkgs; [
      kdePackages.kate
      sbctl
    ];
    services.tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "client";
    };

    system.stateVersion = "26.05";
  };
}
