{
  config,
  pkgs,
  lib,
  ...
}: {
  nixpkgs.overlays = [
    (self: super: {
      wordpressPackages = builtins.fetchGit {
        url = "https://git.helsinki.tools/helsinki-systems/wp4nix";
        ref = "master";
      };
    })
  ];
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
  # services.home-assistant = {
  #   enable = true;
  #   extraComponents = [
  #     # Components required to complete the onboarding
  #     "analytics"
  #     "google_translate"
  #     "met"
  #     "radio_browser"
  #     "shopping_list"
  #     # Recommended for fast zlib compression
  #     # https://www.home-assistant.io/integrations/isal
  #     "isal"
  #   ];
  #   config = {
  #     # Includes dependencies for a basic setup
  #     # https://www.home-assistant.io/integrations/default_config/
  #     default_config = { };
  #   };
  # };

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
    package = pkgs.nextcloud33;
    # [...]
    # Instead of using pkgs.nextcloud29Packages.apps or similar,
    # we'll reference the package version specified in services.nextcloud.package
    extraApps = {
      inherit
        (config.services.nextcloud.package.packages.apps)
        calendar
        contacts
        mail
        notes
        onlyoffice
        tasks
        cospend
        phonetrack
        news
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
      "wordpress.cowgoesmoopiggoesoink.com".email = "ksio2124@protonmail.ch";
    };
  };

  containers.wordpress = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "10.0.0.1";
    # hostBridge = "tap0"; # Specify the bridge name
    localAddress = "10.0.0.3";
    config = {
      config,
      pkgs,
      lib,
      ...
    }: let
      wordpress-theme-responsive = pkgs.stdenv.mkDerivation rec {
        name = "responsive";
        version = "4.7.9";
        src = pkgs.fetchzip {
          url = "https://downloads.wordpress.org/theme/responsive.${version}.zip";
          hash = "sha256-7K/pwD1KAuipeOAOLXd2wqOUEhwk+uNGIllVWzDHzp0=";
        };
        installPhase = "mkdir -p $out; cp -R * $out/";
      };
    in {
      services.wordpress.sites."wordpress.cowgoesmoopiggoesoink.com" = {
        settings = {
          # Needed to run behind reverse proxy
          FORCE_SSL_ADMIN = true;
        };
        extraConfig = ''
          $_SERVER['HTTPS']='on';
        '';
        themes = {
          inherit (pkgs.wordpressPackages.themes) twentytwentyfive;
          inherit wordpress-theme-responsive;
        };
      };
      networking.firewall.allowedTCPPorts = [80];
      system.stateVersion = "26.05"; # Required for running NixOS containers
    };
  };
  services.nginx.virtualHosts."wordpress.cowgoesmoopiggoesoink.com" = {
    #  services.nginx.virtualHosts.${config.services.nextcloud.hostName} = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://10.0.0.3";
      # return = "301 http://example.com$request_uri";
    };
  };
}
