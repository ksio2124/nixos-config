{
  config,
  pkgs,
  lib,
  ...
}:

{

  services.nginx = {
    enable = true;

    # Use recommended settings
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    # Only allow PFS-enabled ciphers with AES256
    sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";

    appendHttpConfig = ''
      # Add HSTS header with preloading to HTTPS requests.
      # Adding this header to HTTP requests is discouraged
      map $scheme $hsts_header {
          https   "max-age=31536000; includeSubdomains; preload";
      }
      add_header Strict-Transport-Security $hsts_header;

      # Enable CSP for your services.
      #add_header Content-Security-Policy "script-src 'self'; object-src 'none'; base-uri 'none';" always;

      # Minimize information leaked to other domains
      add_header 'Referrer-Policy' 'origin-when-cross-origin';

      # Disable embedding as a frame
      add_header X-Frame-Options DENY;

      # Prevent injection of code in other mime types (XSS Attacks)
      add_header X-Content-Type-Options nosniff;

      # This might create errors
      proxy_cookie_path / "/; secure; HttpOnly; SameSite=strict";
    '';

  };
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

  sops.secrets."nextcloud/adminpass" = {
    owner = "nextcloud";
    group = "nextcloud";
  };
  services.nextcloud = {
    enable = true;
    hostName = "nextcloud.cowgoesmoopiggoesoink.com";
    https = true;
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
      adminpassFile = config.sops.secrets."nextcloud/adminpass".path;
    };
  };

  services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
    forceSSL = true;
    enableACME = true;
  };

  security.acme = {
    acceptTerms = true;
    certs = {
      ${config.services.nextcloud.hostName}.email = "ksio2124@protonmail.ch";
    };
  };

}
