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
      self.homeModules.homeDevelopment
    ];
    nixpkgs.overlays = [inputs.nur.overlays.default];

    home.username = "jack";
    home.homeDirectory = "/home/jack";
    home.packages = [
      pkgs.discord
      pkgs.zoom-us
      pkgs.vlc
      pkgs.lmstudio
      pkgs.moonlight-qt
      pkgs.libreoffice
      pkgs.gimp
      pkgs.figma-linux
      pkgs.signal-desktop
      pkgs.godot_4
      pkgs.gpu-screen-recorder-gtk
      pkgs.mangohud
      pkgs.protonup-ng
      pkgs.lutris
      pkgs.bottles
      pkgs.calibre
      pkgs.unciv
      pkgs.endless-sky
      pkgs.freecad
      pkgs.tesseract
      pkgs.imagemagickBig
      pkgs.google-chrome
      pkgs.xournalpp
      pkgs.retroarch-free
      pkgs.gnomeExtensions.caffeine
      pkgs.gnomeExtensions.astra-monitor
      pkgs.gnomeExtensions.bluetooth-battery-meter
      pkgs.gnomeExtensions.gsconnect
      pkgs.wireshark
      pkgs.cisco-packet-tracer_9
      pkgs.unigine-superposition
      pkgs.freetube
      pkgs.kiwix
      pkgs.opencode
      pkgs.wl-clipboard
      pkgs.anki
      pkgs.wesnoth
      pkgs.stremio-linux-shell
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
      mpv = {
        enable = true;
      };
      thunderbird.enable = true;
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
