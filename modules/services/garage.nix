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
        "--load-credential=garage-rpcSecret:${config.sops.secrets."garage/rpcSecret".path}"
        "--load-credential=garage-adminToken:${config.sops.secrets."garage/adminToken".path}"
        "--bind=/mypool/garage/data:/mypool/garage/data:idmap"
        "--bind=/var/lib/garage/meta:/var/lib/garage/meta:idmap"
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

        # Only reachable from the isolated br-isolated network (host nginx
        # proxies in from there) - same trust model as postgres's port 5432.
        networking.firewall.allowedTCPPorts = [3900 3902];
        system.stateVersion = "26.05"; # Required for running NixOS containers
      };
    };
  };
}
