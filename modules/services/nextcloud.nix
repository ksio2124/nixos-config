{
  flake.nixosModules.nextcloud = {config, ...}: {
    sops.secrets."nextcloud/postgresqlpass" = {};

    # Both nextcloud and postgresql containers autostart in parallel at
    # boot, and nextcloud-setup.service (the occ install/upgrade step)
    # runs once with no retry. It consistently loses the race and fails
    # because Postgres hasn't opened its listening socket yet, leaving
    # Nextcloud non-functional until someone manually restarts the unit.
    # Ordering the container units fixes it at the source.
    systemd.services."container@nextcloud" = {
      after = ["container@postgresql.service"];
      requires = ["container@postgresql.service"];
    };

    containers.nextcloud = {
      autoStart = true;
      # ephemeral = true;
      privateNetwork = true;
      hostBridge = "br-isolated";
      localAddress6 = "fdcf:4b47:cf30::11/64";
      privateUsers = "pick";
      extraFlags = [
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
        # The mailserver has an IPv6 address on its private veth. Pin this
        # hostname here because the internal DNS A record still serves LAN
        # clients that use the mailserver's IPv4 address.
        networking.hosts."fdcf:4b47:cf30:1::2" = ["mail.ksio2124.com"];

        # nextcloud-setup.service (occ install/upgrade) runs once at boot
        # with no retry, and has been observed failing transiently right
        # after container start - either the DB isn't accepting
        # connections yet or DNS resolution for postgresql.home isn't
        # ready yet. Retry instead of leaving Nextcloud broken until a
        # manual restart.
        systemd.services.nextcloud-setup.serviceConfig = {
          Restart = "on-failure";
          RestartSec = "5s";
        };

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
          package = pkgs.nextcloud35;
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
              # news and memories are not yet packaged for nextcloud35 in
              # nixpkgs (both throw "does not support nextcloud version 35");
              # re-add once nixpkgs catches up.
              ;
          };
          https = true;
          extraAppsEnable = true;
          datadir = "/mypool/nextcloud";
          caching.redis = true;
          settings = {
            default_phone_region = "US";
            maintenance_window_start = 3;
          };
          phpOptions = {
            "opcache.interned_strings_buffer" = 32;
          };
          config = {
            dbtype = "pgsql";
            dbpassFile = "/run/credentials/@system/nextcloud-postgresqlpass";
            dbhost = "postgresql.home:5432";
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
