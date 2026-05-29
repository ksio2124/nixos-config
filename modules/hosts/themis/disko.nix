{
  disko.devices = {
    disk = {
      zfs-seagate-smr = {
        device = "/dev/disk/by-id/ata-ST4000LM024-2AN17V_WCKAWASF";
        type = "disk";
        content = {
          gpt = {
            partitions = {
              zfs = {
                size = "100%";
                content = {
                  type = "zfs";
                  pool = "mypool";
                };
              };
            };
          };
        };
      };
      zfs-generic-hdd = {
        device = "/dev/disk/by-id/ata-MB4000GVYZK_ZC17EW3T";
        type = "disk";
        content = {
          gpt = {
            partitions = {
              zfs = {
                size = "100%";
                content = {
                  type = "zfs";
                  pool = "mypool";
                };
              };
            };
          };
        };
      };
      zfs-toshiba-cloud = {
        device = "/dev/disk/by-id/ata-TOSHIBA_MC04ACA400E_70HGK24CFLSA";
        type = "disk";
        content = {
          gpt = {
            partitions = {
              zfs = {
                size = "100%";
                content = {
                  type = "zfs";
                  pool = "mypool";
                };
              };
            };
          };
        };
      };
    };

    zpool = {
      mypool = {
        type = "zpool";
        mode = "raidz1";
        options = {
          ashift = "12"; # Optimal 4K block size layout alignment
        };
        rootFsOptions = {
          compression = "zstd";
          acltype = "posixacl";
          xattr = "sa";

          # Native SMR Performance Mitigations
          recordsize = "1M"; # Drastically reduces SMR write cycles
          atime = "off"; # Drops read-to-write performance hits

          # Security Infrastructure
          encryption = "aes-256-gcm";
          keyformat = "raw";
          keylocation = "file:///etc/zfs/mypool.key";
          mountpoint = "legacy";
        };
        mountpoint = "/mypool";
      };
    };
  };
}
