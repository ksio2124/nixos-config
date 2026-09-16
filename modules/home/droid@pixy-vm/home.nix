{
  inputs,
  self,
  ...
}: {
  flake.homeConfigurations."droid@pixy-vm" = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.aarch64-linux;
    modules = [
      self.homeModules."homeDroid@pixy-vm"
    ];
  };

  flake.homeModules."homeDroid@pixy-vm" = {pkgs, ...}: {
    # pkgs
    imports = [
      self.homeModules.homeEditor
      self.homeModules.homeShell
      self.homeModules.homeSystem_tools
      self.homeModules.homeDevelopment
      self.homeModules.homeOpencode
      inputs.sops-nix.homeManagerModules.sops
    ];

    nix.package = pkgs.nix;
    nix.settings = {
      experimental-features = ["nix-command" "flakes"];
      extra-substituters = ["https://nix-community.cachix.org"];
      extra-trusted-public-keys = ["nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="];
    };
    sops = {
      defaultSopsFile = ./secrets/config.yaml;
      age.keyFile = "/home/droid/.config/sops/age/keys.txt";
    };
    home.packages = [
      pkgs.tailscale
      pkgs.nerd-fonts.fira-code
      pkgs.nerd-fonts.droid-sans-mono
    ];
    fonts.fontconfig.enable = true;

    home.username = "droid";
    home.homeDirectory = "/home/droid";

    # The state version is required and should stay at the version you
    # originally installed.
    home.stateVersion = "25.05";
  };
}
