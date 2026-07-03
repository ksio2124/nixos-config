{
  flake.nixosModules.nextcloud = {config, ...}: {
    sops.secrets."nextcloud/adminpass" = {};
    containers.nextcloud = {
      autoStart = true;
      privateNetwork = true;
      hostBridge = "br-isolated";
      privateUsers = "pick";
      extraFlags = [
        "--load-credential=nextcloud-adminpass:${config.sops.secrets."nextcloud/adminpass".path}"
        "--load-credential=cloudflare-ddns-credentials:${config.sops.secrets."cloudflare-ddns/credentials".path}"
        "--bind=/mypool/nextcloud:/mypool/nextcloud:idmap"
      ];
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
            adminpassFile = "/run/credentials/@system/nextcloud-adminpass";
          };
          appstoreEnable = false;
        };
        services.cloudflare-ddns = {
          enable = true;
          credentialsFile = "/run/credentials/@system/cloudflare-ddns-credentials";
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
