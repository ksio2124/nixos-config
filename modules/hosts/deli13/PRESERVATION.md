# deli13 Preservation

The root filesystem becomes a 1 GiB tmpfs. The existing LUKS-encrypted ext4
filesystem mounts at `/persistent`; its contents are retained in place.
No repartitioning, formatting, or bulk data migration is required.

| Path | Backing storage |
| --- | --- |
| `/` | tmpfs, fresh at every boot |
| `/persistent` | Existing encrypted ext4 root |
| `/nix`, `/home`, `/tmp`, `/var/tmp` | Bind mounts of the existing directories under `/persistent` |
| `/var/lib`, `/var/log`, `/var/cache`, `/var/spool`, `/root` | Preservation bind mounts |
| `/etc/NetworkManager/system-connections`, `/etc/ssh`, `/etc/nixos` | Preservation bind mounts |
| `/etc/machine-id` | Preserved during initrd |
| Account database | Userborn uses the existing files in `/persistent/etc` |
| Swap | Existing 16 GiB file at `/persistent/var/lib/swapfile`, with zswap |
| `/boot` | Existing EFI partition |

Preserving all of `/var/lib` retains sbctl signing keys, NixOS account allocation
state, Bluetooth pairings, fwupd state, and other service data. Home Manager's
profiles, caches, credentials, and this checkout stay on disk under `/home`.
Unused temporary files are eligible for cleanup after 10 days in `/tmp` and
30 days in `/var/tmp`; persistence does not mean temporary files are kept forever.
Large temporary work and Nix builds stay off the small tmpfs root. `/run` and
`/dev/shm` remain volatile RAM-backed runtime storage.

## Before the first boot

Back up personal files, the LUKS header, and `/var/lib/sbctl` securely outside the
laptop. Keep a NixOS recovery USB and the disk passphrase available.
Do not delete or reorganize the old root contents.

Check that the existing source directories and identity files are present:

```sh
sudo test -d /nix/store
sudo test -d /home/jack
sudo test -d /tmp
sudo test -d /var/tmp
sudo test -d /var/lib/nixos
sudo test -d /var/lib/sbctl/keys
sudo test -s /etc/passwd
sudo test -s /etc/group
sudo test -s /etc/shadow
sudo test -s /etc/machine-id
sudo test -f /var/lib/swapfile
sudo sbctl status
df -h /boot
```

Each `test` should exit successfully. Investigate failures before continuing.
If `/etc/passwd`, `/etc/group`, or `/etc/shadow` has become a symlink since this
configuration was prepared, stop and check its target: the persistent account
database must consist of real, usable files, not stale links into the old root.

Build first from this checkout:

```sh
nix build --no-link '.#nixosConfigurations.deli13.config.system.build.toplevel'
```

Record the current system path as a recovery reference:

```sh
readlink -f /run/current-system
```

After explicit approval to update the boot generation, install for the next boot:

```sh
sudo nixos-rebuild boot --flake .#deli13
sudo sbctl verify
```

Use `boot`, not `switch` or `test`, for this first transition: the live root is
still the original ext4 mount. Do not attempt to remount it as tmpfs in place.
Reboot manually after confirming bootloader installation succeeded.

## Verify after boot

```sh
findmnt /
findmnt /persistent
findmnt /nix
findmnt /home
findmnt /tmp
findmnt /var/tmp
findmnt /var/lib
swapon --show
cat /sys/module/zswap/parameters/enabled
sudo sbctl status
systemctl --failed
stat -c '%a %n' /tmp /var/tmp
```

Expect tmpfs at `/`, encrypted ext4 at `/persistent`, disk-backed bind mounts,
16 GiB swap, zswap `Y`, and temporary directories with permissions `1777`.
Confirm login, Wi-Fi, Bluetooth, applications, Steam, and Home Manager still work.
Create one harmless marker under `/` and another under `/home/jack`, then reboot:
the root marker should disappear and the home marker should survive.

## Recovery

First try the previous signed NixOS generation in the boot menu. It mounts the
original ext4 filesystem at `/`; the existing `nix`, `home`, `etc`, and `var`
contents have not been moved or deleted. Changes made to persistent data after
the transition are shared with the old layout; a generation rollback is not a
data rollback.

If the previous generation cannot boot, use a recovery USB. Firmware Secure Boot
may need to be temporarily disabled to boot that USB. Identify the disk with
`lsblk -f`, unlock its LUKS partition, mount the ext4 filesystem and EFI partition,
and repair the boot configuration using the saved previous system path. Do not
format either partition. Revert the filesystem and Preservation configuration
before rebuilding the old layout from source.
