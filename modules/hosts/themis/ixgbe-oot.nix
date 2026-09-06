{...}: {
  flake.nixosModules.hostThemis = {
    pkgs,
    config,
    ...
  }: {
    # Out-of-tree ixgbe driver, built from Intel's upstream source, to satisfy
    # nvmupdate64e when flashing NVM/firmware on the X550-T2 ports (wan/lan0).
    # The in-tree kernel ixgbe refuses nvmupdate64e's raw device-memory access
    # ("cannot be updated due to inaccessible device memory"); Intel's own
    # out-of-tree build exposes what the tool needs. Remove this module once
    # the firmware flash is done — it's not needed for normal operation.
    boot.extraModulePackages = let
      kernel = config.boot.kernelPackages.kernel;
    in [
      (pkgs.stdenv.mkDerivation rec {
        pname = "ixgbe";
        version = "6.4.5";
        name = "${pname}-${version}-${kernel.version}";

        src = pkgs.fetchFromGitHub {
          owner = "intel";
          repo = "ethernet-linux-ixgbe";
          tag = "v${version}";
          hash = "sha256-ZAPA4kdH4hDGHgMC5ohDpRylWqgUh4pWUUumVbWmUNg=";
        };

        nativeBuildInputs = kernel.moduleBuildDependencies ++ [pkgs.which];

        hardeningDisable = ["pic"];

        configurePhase = ''
          cd src
          # Nix exports the `src` derivation attribute as $src; common.mk's own
          # `src ?= ...` then never fires since the env var already "sets" it,
          # leaving make pointed at the read-only fetched source instead of
          # this writable build directory.
          unset src
          # Nix splits the kernel .dev output into source/ (full headers,
          # scripts) and build/ (configured .config/generated output);
          # common.mk expects KSRC=source with KOBJ=build for this layout.
          makeFlagsArray+=(KSRC=${kernel.dev}/lib/modules/${kernel.modDirVersion}/source KOBJ=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build INSTALL_MOD_PATH=$out MANDIR=/share/man)
          substituteInPlace common.mk --replace-quiet /sbin/depmod ${pkgs.kmod}/bin/depmod
          # prevent host system kernel introspection
          substituteInPlace common.mk --replace-quiet /boot/System.map /not-exists
        '';

        enableParallelBuilding = true;

        # `make modules_install` runs depmod over the whole $out tree, which
        # writes top-level modules.* index files that collide with the other
        # extraModulePackages (zfs, vmware) when NixOS merges them via
        # buildEnv. Only the actual .ko under lib/modules/*/updates/ is needed.
        postInstall = ''
          rm -f $out/lib/modules/${kernel.modDirVersion}/modules.*
        '';

        meta = {
          description = "Intel(R) 10GbE PCI Express ixgbe driver, built out-of-tree for nvmupdate64e NVM flashing";
          homepage = "https://github.com/intel/ethernet-linux-ixgbe";
          license = pkgs.lib.licenses.gpl2Only;
          platforms = pkgs.lib.platforms.linux;
        };
      })
    ];
  };
}
