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

    boot.loader.systemd-boot.enable = lib.mkForce false;

    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };

    # boot.initrd.luks.devices."luks-302884b2-eb84-4c96-a1b3-f86c7c23cda4".device = "/dev/disk/by-uuid/302884b2-eb84-4c96-a1b3-f86c7c23cda4";
    boot.initrd.luks.devices."luks-302884b2-eb84-4c96-a1b3-f86c7c23cda4" = {
      device = "/dev/disk/by-uuid/302884b2-eb84-4c96-a1b3-f86c7c23cda4";
      allowDiscards = true;
      keyFileSize = 4096;
      keyFile = "/dev/disk/by-id/usb-PNY_USB_2.0_FD_AF822H06YD34000995-0:0";
      fallbackToPassword = true;
    };

    # swap devices is also encrypted
    # boot.initrd.luks.devices."luks-0deec53c-037f-44d6-89b0-45aa2077dcda".device =
    #   "/dev/disk/by-uuid/0deec53c-037f-44d6-89b0-45aa2077dcda";
    boot.initrd.luks.devices."luks-0deec53c-037f-44d6-89b0-45aa2077dcda" = {
      device = "/dev/disk/by-uuid/0deec53c-037f-44d6-89b0-45aa2077dcda";
      allowDiscards = true;
      keyFileSize = 4096;
      keyFile = "/dev/disk/by-id/usb-PNY_USB_2.0_FD_AF822H06YD34000995-0:0";
      fallbackToPassword = true;
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

    # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
    # (the default) this is the recommended approach. When using systemd-networkd it's
    # still possible to use this option, but it's recommended to use it in conjunction
    # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
    # networking.useDHCP = lib.mkDefault true;
    # networking.interfaces.eno1.useDHCP = lib.mkDefault true;
    # networking.interfaces.ens2f0.useDHCP = lib.mkDefault true;
    # networking.interfaces.ens2f1.useDHCP = lib.mkDefault true;
    # networking.interfaces.ens2f2.useDHCP = lib.mkDefault true;
    # networking.interfaces.ens2f3.useDHCP = lib.mkDefault true;
    # networking.interfaces.ens3f0.useDHCP = lib.mkDefault true;
    # networking.interfaces.ens3f1.useDHCP = lib.mkDefault true;

    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
    hardware.enableAllFirmware = true;
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
