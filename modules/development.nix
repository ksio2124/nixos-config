_: {
  flake.homeModules.homeDevelopment = {pkgs, ...}: {
    # pkgs
    imports = [
      # import homeModules here
    ];
    home.packages = [
      pkgs.nixd
      pkgs.alejandra
      pkgs.nixfmt
      pkgs.statix
      pkgs.deadnix
      pkgs.yaml-language-server
      pkgs.devenv
      pkgs.hugo
    ];
  };
}
