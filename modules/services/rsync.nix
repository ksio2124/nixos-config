{
  flake.nixosModules.rsync = {config, ...}: {
    containers.rsync = {
      autoStart = true;
      #ephemeral = true;
      privateNetwork = true;
      localAddress6 = "fdcf:4b47:cf30::14/64";
      hostBridge = "br-isolated";
      privateUsers = "pick";
      extraFlags = [
        "--load-credential=cloudflare-ddns-credentials:${config.sops.secrets."cloudflare-ddns/credentials".path}"
        "--bind=/mypool/rsync:/home:idmap"
      ];
      config = {
        config,
        pkgs,
        ...
      }: {
        nixpkgs.config.allowUnfree = true;
        environment.systemPackages = [
          pkgs.rsync
        ];
        networking.nameservers = ["fdcf:4b47:cf30::1"];
        services.nginx.enable = true;
        services.nginx.virtualHosts."rsync.ksio2124.com" = {
          forceSSL = true;
          enableACME = true;
        };
        users.users.phi = {
          isNormalUser = true;
        };
        services.openssh = {
          enable = true;
          settings = {
            PermitRootLogin = "no";
            AllowUsers = ["phi"];
          };
        };
        security.acme = {
          acceptTerms = true;
          defaults.email = "ksio2124@protonmail.ch";
        };
        services.cloudflare-ddns = {
          enable = true;
          credentialsFile = "/run/credentials/@system/cloudflare-ddns-credentials";
          ip6Domains = [
            "rsync.ksio2124.com"
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
