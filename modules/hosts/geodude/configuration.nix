{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.geodude = inputs.nixpkgs.lib.nixosSystem {
    modules = [self.nixosModules.hostGeodude];
  };

  flake.nixosModules.hostGeodude = {pkgs, ...}: {
    imports = [self.nixosModules.nix];

    boot.loader.grub.enable = false;
    boot.loader.generic-extlinux-compatible.enable = true;
    boot.kernelParams = [
      "console=tty1"
      "console=ttyS2,1500000n8"
    ];
    # U-Boot is provisioned separately with ubootRock64v2. Its saved environment
    # must retain ramdisk_addr_r=0x10000000 and fdt_addr_r=0x20000000.

    networking.hostName = "geodude";
    networking.networkmanager.enable = true;
    services.openssh.enable = true;

    # Preserve the SD image's existing login during the migration to jack.
    # Existing password hashes are retained; set jack's password before logout.
    users.users.nixos = {
      isNormalUser = true;
      uid = 1000;
      extraGroups = ["wheel" "networkmanager"];
    };

    time.timeZone = "America/Los_Angeles";
    i18n.defaultLocale = "en_US.UTF-8";
    hardware.enableAllFirmware = true;
    hardware.graphics.enable = true;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
    programs.git.enable = true;
    environment.systemPackages = with pkgs; [
      home-manager
      usbutils
      alsa-utils
    ];

    # Preserve the version from the generated Rock64 configuration.
    system.stateVersion = "26.11";
  };
}
