{
  flake.nixosModules.hostDeli13 = {
    config,
    lib,
    modulesPath,
    ...
  }: {
    imports = [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

    boot.initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "uas"
      "sd_mod"
      "rtsx_pci_sdmmc"
    ];
    boot.initrd.kernelModules = [];
    boot.kernelModules = ["kvm-intel"];
    boot.extraModulePackages = [];

    fileSystems."/" = {
      device = "none";
      fsType = "tmpfs";
      options = ["size=1G" "mode=0755"];
    };

    fileSystems."/persistent" = {
      device = "/dev/mapper/luks-6e71c670-7288-401d-8f78-0752b03ac28c";
      fsType = "ext4";
      neededForBoot = true;
    };

    boot.initrd.luks.devices."luks-6e71c670-7288-401d-8f78-0752b03ac28c".device = "/dev/disk/by-uuid/6e71c670-7288-401d-8f78-0752b03ac28c";

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/3F17-3887";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };

    # Stored inside the LUKS-encrypted root filesystem, using its existing key.
    swapDevices = [
      {
        device = "/persistent/var/lib/swapfile";
        size = 16 * 1024; # MiB
      }
    ];

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
