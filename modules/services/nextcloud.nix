{
  flake.nixosModules.nextcloud = {config, ...}: {
    sops.secrets."nextcloud/adminpass" = {};
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
        ...
      }: {
        services.nginx.virtualHosts."nextcloud.cowgoesmoopiggoesoink.com" = {
          extraConfig = ''

            # Disable buffering to avoid disk I/O bottlenecks during upload
            proxy_buffering off;
            fastcgi_request_buffering off;
          '';
        };
        #     services.nginx.virtualHosts."localhost" = {
        #       # This automatically sets up SSL via Let's Encrypt (replaces Caddy's auto-SSL)
        #       forceSSL = true;
        #       enableACME = true;
        #
        #       locations."/" = {
        #         proxyPass = "http://127.0.0.1:8000";
        #         proxyWebsockets = true; # Necessary for OnlyOffice document editing
        #         extraConfig = ''
        #           # This is the direct equivalent to your header_up line
        #           proxy_set_header X-Forwarded-Proto https;
        #
        #           # Standard proxy headers usually needed
        #           proxy_set_header Host $host;
        #           proxy_set_header X-Real-IP $remote_addr;
        #         '';
        #       };
        #     };
        #
        #     security.acme.acceptTerms = true;
        #
        # security.acme.certs."localhost".email = "ksio2124@protonmail.cih";
        #
        #     services.onlyoffice = {
        #       enable = true;
        #       hostname = "localhost";
        #       securityNonceFile = "${pkgs.writeText "nixos-test-onlyoffice-nonce.conf" ''
        #         set $secure_link_secret "nixostest";
        #       ''}";
        #     };

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
              #richdocuments
              tasks
              cospend
              phonetrack
              news
              memories
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
        # Prevent the host from overwriting resolv.conf with its own potentially invalid one
        networking.useHostResolvConf = false;

        # Manually set reliable public DNS servers
        networking.nameservers = ["1.1.1.1" "8.8.8.8"];
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

    security.acme.certs."nextcloud.cowgoesmoopiggoesoink.com".email = "ksio2124@protonmail.ch";
  };
}
