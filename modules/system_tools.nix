_: {
  flake.homeModules.homeSystem_tools = {
    pkgs,
    ...
  }: {
    nixpkgs.config.permittedInsecurePackages = [
      "ventoy-1.1.18"
    ];
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
      pkgs.unzip
      pkgs.android-tools
      pkgs.signify
      pkgs.libarchive
      pkgs.universal-android-debloater
      pkgs.nmap
      pkgs.binutils
      pkgs.ffmpeg
      pkgs.jq
      pkgs.browsh
      pkgs.smartmontools
      pkgs.awscli2
      pkgs.pv
      pkgs.dig
      pkgs.net-tools
      pkgs.tcpdump
      pkgs.traceroute
      pkgs.quickemu
      pkgs.s5cmd
      pkgs.mbuffer
      pkgs.tree
      pkgs.popsicle
      pkgs.patchelf
      pkgs.file
      pkgs.usbutils
      pkgs.socat
      pkgs.openssl
      pkgs.gparted-full
      pkgs.ventoy-full
      pkgs.iw
      pkgs.rclone
      pkgs.opentofu
      pkgs.neomutt
      pkgs.msmtp
      # pkgs.rclone-ui
    ];
    programs = {
      yt-dlp.enable = true;
      ripgrep.enable = true;
      fd.enable = true;
      gh.enable = true;
      zellij.enable = true;
      fastfetch = {
        enable = true;
      };
    };
  };
}
