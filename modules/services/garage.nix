{
  flake.nixosModules.garage = {config, ...}: {
    sops.secrets."garage/rpcSecret" = {};
    sops.secrets."garage/adminToken" = {};
    sops.secrets."garage/cloudflareDnsToken" = {};
    containers.garage = {
      autoStart = true;
      ephemeral = true;
      privateNetwork = true;
      hostBridge = "br-isolated";
      localAddress6 = "fdcf:4b47:cf30::17/64";
      privateUsers = "pick";

      extraFlags = [
        "--load-credential=cloudflare-ddns-credentials:${config.sops.secrets."cloudflare-ddns/credentials".path}"
        "--load-credential=garage-rpcSecret:${config.sops.secrets."garage/rpcSecret".path}"
        "--load-credential=garage-adminToken:${config.sops.secrets."garage/adminToken".path}"
        "--load-credential=garage-cloudflareDnsToken:${config.sops.secrets."garage/cloudflareDnsToken".path}"
        "--bind=/mypool/garage/data:/mypool/garage/data:idmap"
        "--bind=/var/lib/garage/meta:/var/lib/garage/meta:idmap"
        # security.acme's cert state isn't otherwise persisted - without
        # this, ephemeral would force a fresh Let's Encrypt issuance
        # (and risk its rate limits) on every container restart.
        "--bind=/var/lib/acme/garage:/var/lib/acme:idmap"
      ];

      config = {
        pkgs,
        lib,
        ...
      }: {
        networking.nameservers = ["fdcf:4b47:cf30::1"];
        networking.useHostResolvConf = false;

        # The upstream module defaults to DynamicUser, which only gets
        # data_dir/metadata_dir ownership right for paths under
        # StateDirectory. Ours live outside that (data_dir on /mypool,
        # metadata_dir's "meta" subdir isn't covered either), so use a
        # fixed user we can chown those paths to instead.
        users.users.garage = {
          isSystemUser = true;
          group = "garage";
        };
        users.groups.garage = {};
        systemd.services.garage.serviceConfig = {
          DynamicUser = lib.mkForce false;
          User = "garage";
          Group = "garage";
          # The raw @system credential files are root-only (0400), so pull
          # them in via LoadCredential instead - this re-exposes them under
          # /run/credentials/garage.service/ readable by the service's own
          # User.
          LoadCredential = [
            "garage-rpcSecret:/run/credentials/@system/garage-rpcSecret"
            "garage-adminToken:/run/credentials/@system/garage-adminToken"
          ];
        };
        systemd.tmpfiles.rules = [
          "d /mypool/garage/data 0750 garage garage - -"
          "d /var/lib/garage/meta 0750 garage garage - -"
        ];

        services.garage = {
          enable = true;
          package = pkgs.garage_2;
          logLevel = "info";

          # rpc_secret/admin_token are deliberately left out of `settings` -
          # that config gets written to /etc/garage.toml in the (world
          # readable) Nix store. These env vars override them at runtime
          # instead, sourced from sops via container credentials.
          extraEnvironment = {
            GARAGE_RPC_SECRET_FILE = "/run/credentials/garage.service/garage-rpcSecret";
            GARAGE_ADMIN_TOKEN_FILE = "/run/credentials/garage.service/garage-adminToken";
          };

          settings = {
            replication_factor = 1;
            db_engine = "lmdb";
            compression_level = 2;

            # Metadata lives on its own host path (fast disk recommended)
            # rather than under /mypool, per upstream recommendation to
            # separate it from the bulk data directory.
            metadata_dir = "/var/lib/garage/meta";
            data_dir = "/mypool/garage/data";

            # Single-node cluster - no peers, so RPC only needs to listen
            # on loopback.
            rpc_bind_addr = "[::1]:3901";
            # rpc_bind_addr is just the listen address, not necessarily
            # dialable - Garage (and the `garage` CLI) need this explicit,
            # reachable address to actually contact this node, otherwise
            # they fall back to guessing 127.0.0.1 and fail to connect.
            rpc_public_addr = "[::1]:3901";

            s3_api = {
              api_bind_addr = "[::]:3900";
              s3_region = "garage";
              # No root_domain - path-style only (s3-api.ksio2124.com/bucket/key).
              # Vhost-style would need its own wildcard cert; the website
              # feature below is the only thing that actually needs one,
              # since it has no path-style fallback.
            };

            s3_web = {
              bind_addr = "[::]:3902";
              # Website hosting is Host-header-only (no path-style
              # fallback), so per-bucket sites need this wildcard suffix:
              # <bucket>.s3-web.ksio2124.com.
              root_domain = "s3-web.ksio2124.com";
            };

            admin = {
              # Loopback only - never proxied through nginx.
              api_bind_addr = "127.0.0.1:3903";
            };
          };
        };

        services.nginx.enable = true;
        services.nginx.virtualHosts."s3-api.ksio2124.com" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://[::1]:3900";
            recommendedProxySettings = true;
            extraConfig = ''
              client_max_body_size 5000M;
              proxy_read_timeout   600s;
              proxy_send_timeout   600s;
              send_timeout         600s;
            '';
          };
        };
        services.nginx.virtualHosts."s3-web.ksio2124.com" = {
          serverAliases = ["*.s3-web.ksio2124.com"];
          forceSSL = true;
          useACMEHost = "s3-web.ksio2124.com";
          locations."/" = {
            proxyPass = "http://[::1]:3902";
            recommendedProxySettings = true;
          };
        };
        security.acme = {
          acceptTerms = true;
          defaults.email = "ksio2124@protonmail.ch";
          certs."s3-web.ksio2124.com" = {
            group = "nginx";
            domain = "*.s3-web.ksio2124.com";
            extraDomainNames = ["s3-web.ksio2124.com"];
            dnsProvider = "cloudflare";
            credentialFiles."CLOUDFLARE_DNS_API_TOKEN_FILE" = "/run/credentials/@system/garage-cloudflareDnsToken";
          };
        };

        services.cloudflare-ddns = {
          enable = true;
          credentialsFile = "/run/credentials/@system/cloudflare-ddns-credentials";
          ip6Domains = [
            "s3-api.ksio2124.com"
            "s3-web.ksio2124.com"
            "*.s3-web.ksio2124.com"
          ];
        };

        networking.firewall.allowedTCPPorts = [80 443];
        system.stateVersion = "26.05"; # Required for running NixOS containers
      };
    };
  };
}
