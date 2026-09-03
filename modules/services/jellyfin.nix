{
  flake.nixosModules.jellyfin = {config, ...}: {
    containers.jellyfin = {
      autoStart = true;
      ephemeral = true;
      privateNetwork = true;
      hostBridge = "br-isolated";
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
      extraFlags = [
        "--load-credential=cloudflare-ddns-credentials:${config.sops.secrets."cloudflare-ddns/credentials".path}"
        "--bind=/mypool/jellyfin:/mypool/jellyfin:idmap"
        "--bind=/dev/dri/card0:/dev/dri/card0"
        "--bind=/dev/dri/renderD129:/dev/dri/renderD129"
      ];
      config = {
        config,
        pkgs,
        ...
      }: {
        nixpkgs.config.allowUnfree = true;
        environment.systemPackages = [
          pkgs.libva-utils
          pkgs.ffmpeg
        ];
        users.users.jellyfin.extraGroups = ["video" "render"];
        # hardware.graphics.enable = true;
        hardware.graphics = {
          enable = true;
          extraPackages = [
            pkgs.intel-ocl
            pkgs.intel-media-driver
            pkgs.intel-compute-runtime-legacy1
          ];
        };
        environment.sessionVariables = {LIBVA_DRIVER_NAME = "iHD";};
        networking.nameservers = ["fdcf:4b47:cf30::1"];
        services.nginx.enable = true;
        services.nginx.virtualHosts."jellyfin.ksio2124.com" = {
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://[::1]:8096";
            proxyWebsockets = true;
            recommendedProxySettings = true;
          };
        };

        services.jellyfin = {
          enable = true;
          openFirewall = true;
          hardwareAcceleration = {
            enable = true;
            device = "/dev/dri/renderD129";
            type = "qsv";
          };

          dataDir = "/mypool/jellyfin";
        };
        security.acme = {
          acceptTerms = true;
          defaults.email = "ksio2124@protonmail.ch";
        };
        services.cloudflare-ddns = {
          enable = true;
          credentialsFile = "/run/credentials/@system/cloudflare-ddns-credentials";
          ip6Domains = [
            "jellyfin.ksio2124.com"
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
