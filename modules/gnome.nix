_: {
  flake.homeModules.homeGnome = {pkgs, ...}: {
    # pkgs
    imports = [
      # import homeModules here
    ];
    home.packages = [
      pkgs.gnomeExtensions.caffeine
      pkgs.gnomeExtensions.astra-monitor
      pkgs.gnomeExtensions.bluetooth-battery-meter
      pkgs.gnomeExtensions.gsconnect
      pkgs.gnomeExtensions.unblank
    ];
    dconf = {
      enable = true;
      settings = {
        "org/gnome/shell" = {
          disable-user-extensions = false; # enables user extensions
          enabled-extensions = [
            pkgs.gnomeExtensions.astra-monitor.extensionUuid
            pkgs.gnomeExtensions.caffeine.extensionUuid
            pkgs.gnomeExtensions.bluetooth-battery-meter.extensionUuid
            pkgs.gnomeExtensions.gsconnect.extensionUuid
            pkgs.gnomeExtensions.unblank.extensionUuid
          ];
        };
      };
    };
  };
}
