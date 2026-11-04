# TODO

## Submit an upstream fix for ROCK64 initrd/kernel overlap

- [ ] Record the reproducer: ROCK64 v2, 4 GiB RAM, `ubootRock64v2` U-Boot 2026.10, NixOS image `26.11pre1107793.1d060086d60c`, Linux 6.18.60.
- [ ] Capture the original U-Boot environment (`printenv kernel_addr_r ramdisk_addr_r fdt_addr_r`) from a clean environment without overwriting the working saved environment.
- [ ] Include the failure: `Moving Image from 0x2080000 to 0x2200000, end=0x6800000`, followed by `ERROR: RD image overlaps OS image (OS=2200000..6800000)`.
- [ ] Document the tested workaround: `setenv ramdisk_addr_r 0x10000000`, `setenv fdt_addr_r 0x20000000`, then `boot`. This reached the NixOS serial login and mounted the SD root filesystem.
- [ ] Check which change is necessary by testing the initrd address independently; both addresses were changed in the successful boot.
- [ ] Locate the ROCK64 default load addresses in upstream U-Boot and check existing issues and fixes; determine whether the permanent patch belongs in U-Boot or nixpkgs.
- [ ] Verify proposed addresses against the memory layout, relocation behavior, and supported RAM sizes (1, 2, and 4 GiB); the workaround has only been tested on this 4 GiB board.
- [ ] Build the patched `ubootRock64v2` and test cold boots, kernel/initrd loading, and persistent environment behavior. Check standard ROCK64 implications too.
- [ ] Prepare an upstream issue or PR with the reproducer, boot logs, patch, and validation results; submit it when ready.
- [ ] Link the upstream issue/PR here and remove any local workaround after the fix is available and verified.
