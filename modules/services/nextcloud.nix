{
  flake.nixosModules.nextcloud = {config, ...}: {
    sops.secrets."nextcloud/adminpass" = {};
    sops.secrets."nextcloud/postgresql" = {};
    containers.nextcloud = {
      autoStart = true;
      privateNetwork = true;
      hostBridge = "br-isolated";
      localAddress6 = "fdcf:4b47:cf30::11/64";
      privateUsers = "pick";
      extraFlags = [
        "--load-credential=nextcloud-adminpass:${config.sops.secrets."nextcloud/adminpass".path}"
        "--load-credential=nextcloud-postgresqlpass:${config.sops.secrets."nextcloud/postgresql".path}"
        "--load-credential=cloudflare-ddns-credentials:${config.sops.secrets."cloudflare-ddns/credentials".path}"
        "--bind=/mypool/nextcloud:/mypool/nextcloud:idmap"
      ];
      config = {
        config,
        pkgs,
        ...
      }: {
        # systemd.network.networks."80-container-eth0" = {
        #   matchConfig.Name = "eth0";
        #   address = ["fdcf:4b47:cf30::11/64"];
        #   networkConfig.IPv6AcceptRA = true;
        # };
        networking.nameservers = ["fdcf:4b47:cf30::1"];
        environment.systemPackages = [
          pkgs.dig
          pkgs.ndisc6
          pkgs.traceroute
          pkgs.postgresql
        ];
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
          # database.createLocally = true;
          caching.redis = true;
          config = {
            adminuser = "ksio2124";
            dbtype = "pgsql";
            dbpassFile = "/run/credentials/@system/nextcloud-postgresql";
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
        # services.resolved.enable = true;
        # Prevent the host from overwriting resolv.conf with its own potentially invalid one
        networking.useHostResolvConf = false;

        networking.firewall.allowedTCPPorts = [80 443];
        system.stateVersion = "26.05"; # Required for running NixOS containers
      };
    };
  };
}
