# TODO

## Package ixgbe in nixpkgs, following ixgbevf

Draft PR: https://github.com/NixOS/nixpkgs/pull/583326 (`linuxPackages.ixgbe: init at 6.4.5`). Builds on x86_64-linux with Linux 6.18.60; Linux >= 7.3 is marked broken after a devlink API build failure on 7.3.1. Runtime hardware validation and maintainer assignment remain before marking ready.

- [ ] Check nixpkgs for an existing ixgbe package or open PR, and inspect the current ixgbevf package and kernel-package registration as the template.
- [ ] Extract the Intel out-of-tree ixgbe derivation from `modules/hosts/themis/ixgbe-oot.nix` into a reusable kernel module package; the local version is currently 6.4.5.
- [ ] Follow ixgbevf's packaging conventions and expose ixgbe through the appropriate `linuxPackages` kernel package sets.
- [ ] Preserve the required build fixes: unset the conflicting `src` environment variable, set `KSRC` and `KOBJ` for split kernel outputs, avoid host kernel introspection, and prevent generated `modules.*` indexes from colliding with other modules.
- [ ] Verify source version/hash, licensing, supported platforms, metadata, and maintainer information for submission.
- [ ] Build against the supported default and latest kernel package sets; validate installation paths and NixOS `boot.extraModulePackages` integration.
- [ ] Record hardware validation on Themis's Intel X550-T2, including interface operation and whether nvmupdate64e can access device memory. Keep firmware flashing separate from package validation.
- [ ] Prepare and submit a nixpkgs PR explaining the use case and differences from the in-tree ixgbe driver; include build and hardware validation results.
- [ ] Link the PR here and replace the local derivation with the nixpkgs package once available, if the out-of-tree driver is still needed.

## Submit an upstream fix for ROCK64 initrd/kernel overlap

Draft PR: https://github.com/NixOS/nixpkgs/pull/583349 (`ubootRock64{,v2}: avoid initrd overlap with large kernels`). Both U-Boot variants cross-build on x86_64-linux for aarch64-linux; compiled initrd/FDT defaults were verified. The recorded saved-environment workaround booted the 4 GiB v2 board. Fresh bootloader flashing/cold boots, smaller RAM variants, compressed kernels, and isolating the FDT change remain untested. Worktree: `/home/jack/Projects/nixpkgs-rock64`, branch `rock64-initrd-overlap`.

- [ ] Record the reproducer: ROCK64 v2, 4 GiB RAM, `ubootRock64v2` U-Boot 2026.10, NixOS image `26.11pre1107793.1d060086d60c`, Linux 6.18.60.
- [ ] Capture the original U-Boot environment (`printenv kernel_addr_r ramdisk_addr_r fdt_addr_r`) from a clean environment without overwriting the working saved environment.
- [ ] Include the failure: `Moving Image from 0x2080000 to 0x2200000, end=0x6800000`, followed by `ERROR: RD image overlaps OS image (OS=2200000..6800000)`.
- [ ] Document the tested workaround: `setenv ramdisk_addr_r 0x10000000`, `setenv fdt_addr_r 0x20000000`, then `boot`. This reached the NixOS serial login and mounted the SD root filesystem.
- [ ] Check which change is necessary by testing the initrd address independently; both addresses were changed in the successful boot.
- [x] Locate the ROCK64 default load addresses in upstream U-Boot and check existing issues and fixes; prepare a ROCK64-scoped nixpkgs patch to the U-Boot defaults.
- [ ] Verify proposed addresses against the memory layout, relocation behavior, and supported RAM sizes (1, 2, and 4 GiB); the workaround has only been tested on this 4 GiB board.
- [ ] Build the patched `ubootRock64v2` and test cold boots, kernel/initrd loading, and persistent environment behavior. Check standard ROCK64 implications too.
- [x] Submit a draft nixpkgs PR with the reproducer, recorded error, patch, successful cross-build checks, and remaining hardware validation.
- [ ] Link the upstream issue/PR here and remove any local workaround after the fix is available and verified.
