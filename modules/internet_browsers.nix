_: {
  flake.homeModules.homeInternet_browsers = {pkgs, ...}: {
    # pkgs
    imports = [
      # import homeModules here
    ];
    programs.firefox = {
      enable = true;
      profiles.default = {
        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          bitwarden
          react-devtools
        ];
      };
    };
  };
}
