{
  flake.nixosModules.nextcloud = {config, ...}: {
    sops.secrets."nextcloud/adminpass" = {};
    sops.secrets."nextcloud/postgresqlpass" = {};
    containers.nextcloud = {
      autoStart = true;
      ephemeral = true;
      privateNetwork = true;
      hostBridge = "br-isolated";
      localAddress6 = "fdcf:4b47:cf30::11/64";
      privateUsers = "pick";
      extraFlags = [
        "--load-credential=nextcloud-adminpass:${config.sops.secrets."nextcloud/adminpass".path}"
        "--load-credential=nextcloud-postgresqlpass:${config.sops.secrets."nextcloud/postgresqlpass".path}"
        "--load-credential=cloudflare-ddns-credentials:${config.sops.secrets."cloudflare-ddns/credentials".path}"
        "--bind=/mypool/nextcloud:/mypool/nextcloud:idmap"
      ];
      config = {
        config,
        pkgs,
        ...
      }: {
        networking.nameservers = ["fdcf:4b47:cf30::1"];

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
          package = pkgs.nextcloud34;
          extraApps = {
            inherit
              (config.services.nextcloud.package.packages.apps)
              calendar
              contacts
              mail
              notes
              onlyoffice
              richdocuments
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
          caching.redis = true;
          config = {
            adminuser = "ksio2124";
            dbtype = "pgsql";
            dbpassFile = "/run/credentials/@system/nextcloud-postgresqlpass";
            dbhost = "postgresql.home:5432";
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

        networking.firewall.allowedTCPPorts = [80 443];
        system.stateVersion = "26.05"; # Required for running NixOS containers
      };
    };
  };
}
