{
  inputs,
  self,
  ...
}: {
  flake.homeConfigurations."jack@themis" = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    modules = [
      self.homeModules."homeJack@themis"
    ];
  };

  flake.homeModules."homeJack@themis" = {pkgs, ...}: {
    # pkgs
    imports = [
      self.homeModules.homeEditor
      self.homeModules.homeShell
      self.homeModules.homeSystem_tools
      self.homeModules.homeDevelopment
      # import homeModules here
    ];

    home = {
      username = "jack";
      homeDirectory = "/home/jack";
    };
    home.stateVersion = "25.05";
  };
}
