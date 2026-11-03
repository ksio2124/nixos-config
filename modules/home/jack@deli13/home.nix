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

    home.stateVersion = "26.05";
  };
}
