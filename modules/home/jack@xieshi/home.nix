{
  inputs,
  self,
  ...
}: {
  flake.homeConfigurations."jack@xieshi" = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    modules = [
      self.homeModules."homeJack@xieshi"
    ];
  };

  flake.homeModules."homeJack@xieshi" = {pkgs, ...}: {
    # pkgs
    imports = [
      self.homeModules.homeEditor
      self.homeModules.homeShell
      self.homeModules.homeSystem_tools
    ];
    nixpkgs.overlays = [inputs.nur.overlays.default];

    home.username = "jack";
    home.homeDirectory = "/home/jack";
    home.packages = [
      pkgs.nixd
      pkgs.alejandra
      # pkgs.lshw
      pkgs.nixfmt
      pkgs.discord
      pkgs.zoom-us
      pkgs.vlc
      pkgs.lmstudio
      pkgs.moonlight-qt
      pkgs.libreoffice
      pkgs.gimp
      pkgs.figma-linux
      pkgs.signal-desktop
      # pkgs.xdvotool
      pkgs.jq
      # pkgs.libva-utils
      pkgs.godot_4
      pkgs.gpu-screen-recorder-gtk
      pkgs.mangohud
      pkgs.protonup-ng
      pkgs.lutris
      pkgs.bottles
      pkgs.calibre
      pkgs.unciv
      pkgs.devenv
      pkgs.endless-sky
      pkgs.freecad
      pkgs.tesseract
      pkgs.imagemagickBig
      # pkgs.poppler-utils
      pkgs.google-chrome
      pkgs.xournalpp
      # pkgs.nvtopPackages.full
      pkgs.lzip
      pkgs.retroarch-free
      # pkgs.sbctl
      # pkgs.btop
      pkgs.gnomeExtensions.caffeine
      pkgs.gnomeExtensions.astra-monitor
      pkgs.gnomeExtensions.bluetooth-battery-meter
      pkgs.gnomeExtensions.gsconnect
      pkgs.wireshark
      # pkgs.qjackctl
      # pkgs.carla
      pkgs.cisco-packet-tracer_9
      pkgs.unigine-superposition
      pkgs.freetube
      pkgs.kiwix
      pkgs.opencode
      pkgs.statix
      pkgs.deadnix
      pkgs.wl-clipboard
      pkgs.anki
      pkgs.wesnoth
      (pkgs.ffmpeg-full.override
        {withUnfree = true;})
    ];
    dconf = {
      enable = true;
      settings = {
        "org/gnome/shell" = {
          disable-user-extensions = false; # enables user extensions
          enabled-extensions = [
            pkgs.gnomeExtensions.astra-monitor.extensionUuid
            pkgs.gnomeExtensions.caffeine.extensionUuid
            pkgs.gnomeExtensions.bluetooth-battery-meter.extensionUuid
            pkgs.gnomeExtensions.gsconnect.extensionUuid
          ];
        };
      };
    };
    programs = {
      chromium.enable = true;
      obs-studio.enable = true;
      yt-dlp.enable = true;
      mpv = {
        enable = true;
        # config = {
        #   hwdec = "vaapi";
        # };
      };
      ripgrep.enable = true;
      fd.enable = true;
    };

    programs.texlive = {
      enable = true;
      extraPackages = tpkgs: {
        inherit (tpkgs) scheme-full;
      };
    };

    programs.firefox = {
      enable = true;
      profiles.default = {
        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          bitwarden
          react-devtools
        ];
      };
    };

    programs.wezterm = {
      enable = true;
      enableZshIntegration = true;
      extraConfig = builtins.readFile ./wezterm.lua;
    };

    # The state version is required and should stay at the version you
    # originally installed.
    home.stateVersion = "25.05";
  };
}
