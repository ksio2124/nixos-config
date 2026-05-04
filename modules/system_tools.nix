_: {
  flake.homeModules.homeSystem_tools = {pkgs, ...}: {
    # pkgs
    imports = [
      # import homeModules here
    ];
    home.packages = [
      pkgs.libva-utils
      pkgs.nvtopPackages.full
      pkgs.sbctl
      pkgs.btop
      pkgs.ndisc6
      pkgs.mtr
      pkgs.iperf3
      pkgs.sops
      pkgs.age
      pkgs.ssh-to-age
      pkgs.ethtool
      pkgs.pciutils
      pkgs.lsof
      pkgs.wireguard-tools
      pkgs.qjackctl #gui tool
      pkgs.carla #gui tool
      pkgs.lshw
      pkgs.lzip
      pkgs.nixd
      pkgs.alejandra
      pkgs.nixfmt
      pkgs.statix
      pkgs.deadnix
      pkgs.unzip
      pkgs.yaml-language-server
      pkgs.android-tools
      pkgs.signify
      pkgs.libarchive
      pkgs.universal-android-debloater
      pkgs.nmap
    ];
  };
}
