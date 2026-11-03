{inputs, ...}: {
  flake.nixosModules.hostDeli13 = {lib, ...}: {
    imports = [inputs.preservation.nixosModules.default];

    boot.tmp.useTmpfs = false;
    boot.tmp.cleanOnBoot = false;

    # Reuse the old root's directories without copying the Nix store or home.
    fileSystems = lib.genAttrs ["/nix" "/home" "/tmp" "/var/tmp"] (path: {
      device = "/persistent${path}";
      fsType = "none";
      options = ["bind" "x-gvfs-hide"];
      depends = ["/persistent"];
      neededForBoot = true;
    });

    # Userborn maintains the existing account database on disk, including
    # passwords, and links it into the volatile /etc.
    services.userborn = {
      enable = true;
      passwordFilesLocation = "/persistent/etc";
    };

    preservation = {
      enable = true;
      preserveAt."/persistent" = {
        directories = [
          # Includes NixOS/userborn state, sbctl keys, Bluetooth, fwupd, and CUPS.
          {
            directory = "/var/lib";
            inInitrd = true;
          }
          "/var/log"
          "/var/cache"
          "/var/spool"
          {
            directory = "/root";
            mode = "0700";
          }
          {
            directory = "/etc/NetworkManager/system-connections";
            mode = "0700";
          }
          "/etc/ssh"
          "/etc/nixos"
        ];
        files = [
          {
            file = "/etc/machine-id";
            inInitrd = true;
          }
        ];
      };
    };

    systemd.suppressedSystemUnits = ["systemd-machine-id-commit.service"];

    # Keep temporary work on disk while removing unused files over time.
    systemd.tmpfiles.rules = [
      "d /tmp 1777 root root 10d"
      "d /var/tmp 1777 root root 30d"
    ];
  };
}
