{
  config,
  pkgs,
  lib,
  ...
}: {
  services.nginx = {
    enable = true;

    # Use recommended settings
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    clientMaxBodySize = "200G";

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

  sops.secrets."nextcloud/adminpass" = {};
  security.acme = {
    acceptTerms = true;
    certs = {
      "wordpress.cowgoesmoopiggoesoink.com".email = "ksio2124@protonmail.ch";
      "nextcloud.cowgoesmoopiggoesoink.com".email = "ksio2124@protonmail.ch";
    };
  };
  containers.nextcloud = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "10.0.0.5";
    localAddress = "10.0.0.6";
    bindMounts."/run/secrets/nextcloud/adminpass" = {
      hostPath = config.sops.secrets."nextcloud/adminpass".path;
    };
    bindMounts."/mypool/nextcloud/" = {
      hostPath = "/mypool/nextcloud/";
      isReadOnly = false;
    };
    config = {
      config,
      pkgs,
      lib,
      ...
    }: {
      services.nginx.virtualHosts."nextcloud.cowgoesmoopiggoesoink.com" = {
        extraConfig = ''

          # Disable buffering to avoid disk I/O bottlenecks during upload
          proxy_buffering off;
          fastcgi_request_buffering off;
        '';
      };
      services.nextcloud = {
        enable = true;
        maxUploadSize = "200G";
        hostName = "nextcloud.cowgoesmoopiggoesoink.com";
        package = pkgs.nextcloud33;
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
        caching.redis = true;
        config = {
          adminuser = "ksio2124";
          dbtype = "mysql";
          adminpassFile = "/run/secrets/nextcloud/adminpass";
        };
        settings = {
          trusted_proxies = ["10.0.0.5"]; # The Host's container IP
          overwriteprotocol = "https";
          log_type = "file";
        };
      };
      networking.firewall.allowedTCPPorts = [80];
      system.stateVersion = "26.05"; # Required for running NixOS containers
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
  services.nginx.virtualHosts."nextcloud.cowgoesmoopiggoesoink.com" = {
    extraConfig = ''
      client_max_body_size 200G;
      proxy_buffering off;
      fastcgi_request_buffering off; # Critical for speed
    '';
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://10.0.0.6";
    };
  };

  services.nginx.virtualHosts."wordpress.cowgoesmoopiggoesoink.com" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://10.0.0.3";
    };
  };
  containers.anki-sync-server = {
    autoStart = true;
    privateNetwork = true;
    hostAddress = "10.0.0.7";
    localAddress = "10.0.0.8";
    config = {
      config,
      pkgs,
      lib,
      ...
    }: {
      services.anki-sync-server = {
        enable = true;
        address = "127.0.0.1";
        users = [
          {
            username = "bob";
            password = "password";
          }
        ];
      };
    };
  };
  services.nginx.virtualHosts."anki-sync-server.cowgoesmoopiggoesoink.com" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {
      proxyPass = "http://10.0.0.8";
    };
  };
}
