{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.firefox-syncserver = {
    config,
    pkgs,
    ...
  }: {
  };
}
