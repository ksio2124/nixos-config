{
  flake.nixosModules.hostThemis = {
    config,
    lib,
    pkgs,
    modulesPath,
    ...
  }: {
    imports = [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

    boot.initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "nvme"
      "usbhid"
      "uas"
      "sd_mod"
    ];
    boot.initrd.kernelModules = ["usb_storage"];
    boot.kernelModules = ["kvm-intel"];
    boot.extraModulePackages = [];

    fileSystems."/" = {
      device = "/dev/disk/by-uuid/74a3cd3f-1a51-4024-8238-c90e35efead7";
      fsType = "ext4";
    };

    boot.loader.systemd-boot.enable = false;

    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };

    boot.initrd.luks.devices."luks-302884b2-eb84-4c96-a1b3-f86c7c23cda4" = {
      device = "/dev/disk/by-uuid/302884b2-eb84-4c96-a1b3-f86c7c23cda4";
      allowDiscards = true;
      keyFileSize = 4096;
      keyFileTimeout = 5;
      keyFile = "/dev/disk/by-id/usb-PNY_USB_2.0_FD_AF822H06YD34000995-0:0";
    };

    boot.initrd.luks.devices."luks-0deec53c-037f-44d6-89b0-45aa2077dcda" = {
      device = "/dev/disk/by-uuid/0deec53c-037f-44d6-89b0-45aa2077dcda";
      allowDiscards = true;
      keyFileSize = 4096;
      keyFileTimeout = 5;
      keyFile = "/dev/disk/by-id/usb-PNY_USB_2.0_FD_AF822H06YD34000995-0:0";
    };

    fileSystems."/boot" = {
      device = "/dev/disk/by-uuid/8B2B-F32B";
      fsType = "vfat";
      options = [
        "fmask=0077"
        "dmask=0077"
      ];
    };

    swapDevices = [
      {device = "/dev/disk/by-uuid/26d6ac9d-1909-4975-bae6-35a85c2d3ebd";}
    ];

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.enableAllFirmware = true;
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
