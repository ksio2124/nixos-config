{
  inputs,
  self,
  ...
}: {
  flake.homeModules.homeShell = {pkgs, ...}: {
    # pkgs
    imports = [
      # import homeModules here
    ];
  };
}
