{
  flake.nixosModules.nextcloud = {config, ...}: {
    sops.secrets."nextcloud/adminpass" = {};
    sops.secrets."cloudflare-ddns/credentials" = {};
    containers.nextcloud = {
      autoStart = true;
      privateNetwork = true;
      hostBridge = "br-isolated";
      bindMounts."/run/secrets/nextcloud/adminpass" = {
        hostPath = config.sops.secrets."nextcloud/adminpass".path;
      };
      bindMounts."/mypool/nextcloud/" = {
        hostPath = "/mypool/nextcloud/";
        isReadOnly = false;
      };
      bindMounts."/run/secrets/cloudflare-ddns/credentials" = {
        hostPath = config.sops.secrets."cloudflare-ddns/credentials".path;
      };
      config = {
        config,
        pkgs,
        ...
      }: {
        services.nginx.virtualHosts."nextcloud.ksio2124.com" = {
          forceSSL = true;
          enableACME = true;
        };
        security.acme = {
          acceptTerms = true;
          certs = {
            "nextcloud.ksio2124.com".email = "ksio2124@protonmail.ch";
          };
        };
        services.nextcloud = {
          enable = true;
          maxUploadSize = "200G";
          hostName = "nextcloud.ksio2124.com";
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
          https = true;
          extraAppsEnable = true;
          datadir = "/mypool/nextcloud";
          database.createLocally = true;
          caching.redis = true;
          config = {
            adminuser = "ksio2124";
            dbtype = "mysql";
            adminpassFile = "/run/secrets/nextcloud/adminpass";
          };
          appstoreEnable = false;
        };
        services.cloudflare-ddns = {
          enable = true;
          credentialsFile = /run/secrets/cloudflare-ddns/credentials;
          ip6Domains = [
            "nextcloud.ksio2124.com"
          ];
        };
        # Prevent the host from overwriting resolv.conf with its own potentially invalid one
        networking.useHostResolvConf = false;

        # Manually set reliable public DNS servers
        networking.nameservers = [
          "2606:4700:4700::1111"
          "2606:4700:4700::1001"
        ];
        networking.firewall.allowedTCPPorts = [80 443];
        system.stateVersion = "26.05"; # Required for running NixOS containers
      };
    };
  };
}
