_: {
  flake.homeModules.homeGames = {pkgs, ...}: {
    # pkgs
    imports = [
      # import homeModules here
    ];
    home.packages = [
      pkgs.unciv
      pkgs.endless-sky
      pkgs.mangohud
      pkgs.retroarch-free
      pkgs.wesnoth
    ];
  };
}
