{
  inputs,
  self,
  ...
}: {
  flake.nixosConfigurations.template = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.hostTemplate
    ];
  };
  flake.nixosModules.hostTemplate = {
    config,
    pkgs,
    ...
  }: {
  };
}
