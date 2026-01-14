{
  config,
  pkgs,
  lib,
  ...
}:

{
  services.home-assistant = {
    enable = true;
    extraComponents = [
      # Components required to complete the onboarding
      "analytics"
      "google_translate"
      "met"
      "radio_browser"
      "shopping_list"
      # Recommended for fast zlib compression
      # https://www.home-assistant.io/integrations/isal
      "isal"
    ];
    config = {
      # Includes dependencies for a basic setup
      # https://www.home-assistant.io/integrations/default_config/
      default_config = { };
    };
  };

  # https://discourse.nixos.org/t/remove-nextcloud-entirely-from-server/31314
  # rm -rf /var/lib/nextcloud
  # ^ to remove nextcloud completely
  services.nextcloud = {
    enable = true;
    hostName = "192.168.1.1";
    package = pkgs.nextcloud32;
    # [...]
    # Instead of using pkgs.nextcloud29Packages.apps or similar,
    # we'll reference the package version specified in services.nextcloud.package
    extraApps = {
      inherit (config.services.nextcloud.package.packages.apps)
        calendar
        contacts
        mail
        notes
        onlyoffice
        tasks
        cospend
        phonetrack
        ;
    };
    extraAppsEnable = true;
    datadir = "/mypool/nextcloud/";
    database.createLocally = true;
    configureRedis = true;
    config = {
      adminuser = "ksio2124";
      dbtype = "mysql";
      adminpassFile = "/mypool/nextcloud/nextcloud_admin.key";
    };
  };

}
