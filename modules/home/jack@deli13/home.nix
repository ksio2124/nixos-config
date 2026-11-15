{
  inputs,
  self,
  ...
}: {
  flake.homeConfigurations."jack@deli13" = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    modules = [
      self.homeModules."homeJack@deli13"
    ];
  };

  flake.homeModules."homeJack@deli13" = {pkgs, ...}: {
    imports = [
      self.homeModules.homeEditor
      self.homeModules.homeShell
      self.homeModules.homeSystem_tools
      self.homeModules.homeDevelopment
      self.homeModules.homeGnome
      self.homeModules.homeGames
      self.homeModules.homeInternet_browsers
      self.homeModules.homeOpencode
    ];

    nixpkgs.overlays = [inputs.nur.overlays.default];

    home.username = "jack";
    home.homeDirectory = "/home/jack";
    home.packages = with pkgs; [
      discord
      zoom-us
      vlc
      lmstudio
      moonlight-qt
      libreoffice
      gimp
      figma-linux
      signal-desktop
      godot_4
      gpu-screen-recorder-gtk
      calibre
      freecad
      tesseract
      imagemagickBig
      google-chrome
      xournalpp
      wireshark
      unigine-superposition
      freetube
      kiwix
      opencode
      wl-clipboard
      anki
      stremio-linux-shell
      proton-vpn
      wechat
      proton-vpn-cli
    ];

    programs = {
      chromium.enable = true;
      obs-studio.enable = true;
      mpv.enable = true;
      thunderbird.enable = true;
    };

    programs.wezterm = {
      enable = true;
      enableZshIntegration = true;
      extraConfig = builtins.readFile ./wezterm.lua;
    };

    i18n.inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        waylandFrontend = true;
        # KWin launches Fcitx with the Wayland input-method connection.
        systemd.enable = false;
        addons = [pkgs.qt6Packages.fcitx5-chinese-addons];
        settings.inputMethod = {
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = "us";
            DefaultIM = "pinyin";
          };
          "Groups/0/Items/0" = {
            Name = "keyboard-us";
            Layout = "";
          };
          "Groups/0/Items/1" = {
            Name = "pinyin";
            Layout = "";
          };
          GroupOrder."0" = "Default";
        };
      };
    };

    home.stateVersion = "26.05";
  };
}
