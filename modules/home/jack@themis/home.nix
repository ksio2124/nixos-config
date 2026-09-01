{
  inputs,
  self,
  ...
}:
{
  flake.homeConfigurations."jack@themis" = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    modules = [
      self.homeModules."homeJack@themis"
    ];
  };

  flake.homeModules."homeJack@themis" = { pkgs, ... }: {
    # pkgs
    imports = [
      self.homeModules.homeEditor
      self.homeModules.homeShell
      self.homeModules.homeSystem_tools
      self.homeModules.homeDevelopment
      self.homeModules.homeInternet_browsers
      self.homeModules.homeGnome
      self.homeModules.homeGames
      self.homeModules.homeOpencode
      inputs.sops-nix.homeManagerModules.sops
      # import homeModules here
    ];

    nixpkgs.overlays = [ inputs.nur.overlays.default ];

    sops.defaultSopsFile = ../../hosts/themis/secrets/config.yaml;
    sops.defaultSopsFormat = "yaml";
    sops.age.sshKeyPaths = [ "/home/jack/.ssh/themis" ];
    sops.age.keyFile = "/home/jack/.config/sops/age/keys.txt";
    sops.age.generateKey = true;

    home = {
      username = "jack";
      homeDirectory = "/home/jack";
    };
    home.stateVersion = "25.05";
  };
}
