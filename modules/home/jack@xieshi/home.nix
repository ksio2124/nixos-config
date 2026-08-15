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
      self.homeModules.homeGnome
      self.homeModules.homeGames
      self.homeModules.homeInternet_browsers
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
      pkgs.calibre
      pkgs.freecad
      pkgs.tesseract
      pkgs.imagemagickBig
      pkgs.google-chrome
      pkgs.xournalpp
      pkgs.wireshark
      pkgs.unigine-superposition
      pkgs.freetube
      pkgs.kiwix
      pkgs.opencode
      pkgs.wl-clipboard
      pkgs.anki
      pkgs.stremio-linux-shell
      pkgs.proton-vpn
      pkgs.proton-vpn-cli
    ];
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
