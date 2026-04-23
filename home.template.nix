{
  inputs,
  self,
  ...
}: {
  flake.homeConfigurations.template = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    modules = [
      self.homeModules.homeTemplate
    ];
  };

  flake.homeModules.homeTemplate = {pkgs, ...}: {
    # pkgs
    imports = [
      # import homeModules here
    ];
  };
}
