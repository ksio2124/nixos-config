{
  flake.nixosModules.immich = {config, ...}: {
    sops.secrets."immich/secretsFile" = {};
    containers.immich = {
      autoStart = true;
      #ephemeral = true;
      privateNetwork = true;
      hostBridge = "br-isolated";
      localAddress6 = "fdcf:4b47:cf30::13/64";
      privateUsers = "pick";

      allowedDevices = [
        {
          node = "/dev/dri/card0";
          modifier = "rw";
        }
        {
          node = "/dev/dri/renderD129";
          modifier = "rw";
        }
      ];
      # bi`ndMounts = {
      #   "/dev/dri/card0" = {
      #     hostPath = "/dev/dri/card0";
      #     isReadOnly = false;
      #   };
      #   "/dev/dri/renderD128" = {
      #     hostPath = "/dev/dri/renderD128";
      #     isReadOnly = false;
      #   };
      # };v
      extraFlags = [
        "--load-credential=cloudflare-ddns-credentials:${config.sops.secrets."cloudflare-ddns/credentials".path}"
        "--load-credential=immich-secretsFile:${config.sops.secrets."immich/secretsFile".path}"
        "--bind=/mypool/immich:/mypool/immich:idmap"
        "--bind=/dev/dri/card0:/dev/dri/card0"
        "--bind=/dev/dri/renderD129:/dev/dri/renderD129"
      ];
      config = {
        config,
        pkgs,
        ...
      }: {
        environment.systemPackages = [
          pkgs.libva-utils
          pkgs.ffmpeg
        ];
        users.users.immich.extraGroups = ["video" "render"];
        # hardware.graphics.enable = true;
        hardware.graphics = {
          enable = true;
          extraPackages = [
            pkgs.intel-media-driver
          ];
        };
        hardware.intel-gpu-tools.enable = true;
        networking.nameservers = ["fdcf:4b47:cf30::1"];
        services.nginx.enable = true;
        services.nginx.virtualHosts."immich.ksio2124.com" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://[::1]:${toString config.services.immich.port}";
            proxyWebsockets = true;
            recommendedProxySettings = true;
            extraConfig = ''
              client_max_body_size 50000M;
              proxy_read_timeout   600s;
              proxy_send_timeout   600s;
              send_timeout         600s;
            '';
          };
        };

        services.immich = {
          enable = true;
          openFirewall = true;
          host = "::";
          database.enable = false;
          database.host = "postgresql.home";
          accelerationDevices = ["/dev/dri/renderD129"];
          mediaLocation = "/mypool/immich";
          secretsFile = "/run/credentials/@system/immich-secretsFile";
        };
        security.acme = {
          acceptTerms = true;
          defaults.email = "ksio2124@protonmail.ch";
        };
        services.cloudflare-ddns = {
          enable = true;
          credentialsFile = "/run/credentials/@system/cloudflare-ddns-credentials";
          ip6Domains = [
            "immich.ksio2124.com"
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
