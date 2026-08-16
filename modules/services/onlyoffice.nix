{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.onlyoffice = {
    config,
    pkgs,
    ...
  }: {
    containers.onlyoffice = {
      # ephemeral = true;
      autoStart = true;
      privateUsers = "pick";
      privateNetwork = true;
      hostBridge = "br-isolated";
      localAddress6 = "fdcf:4b47:cf30::12/64";
      extraFlags = [
        "--load-credential=cloudflare-ddns-credentials:${config.sops.secrets."cloudflare-ddns/credentials".path}"
      ];
      config = {
        config,
        pkgs,
        ...
      }: {
        services.onlyoffice = {
          enable = true;
          hostname = "onlyoffice.ksio2124.com";
          rabbitmqUrl = "amqp://guest:guest@127.0.0.1:5672";
          securityNonceFile = "${pkgs.writeText "nixos-test-onlyoffice-nonce.conf" ''
            set $secure_link_secret "nixostest";
          ''}";
        };
        networking.useHostResolvConf = false;

        # Manually set reliable public DNS servers
        networking.nameservers = ["fdcf:4b47:cf30::1"];
        networking.firewall.allowedTCPPorts = [80 443];
        system.stateVersion = "26.05";
        services.nginx.virtualHosts."onlyoffice.ksio2124.com" = {
          forceSSL = true;
          enableACME = true;
        };
        security.acme = {
          acceptTerms = true;
          defaults.email = "ksio2124@protonmail.ch";
        };
        services.cloudflare-ddns = {
          enable = true;
          credentialsFile = "/run/credentials/@system/cloudflare-ddns-credentials";
          ip6Domains = [
            "onlyoffice.ksio2124.com"
          ];
        };
      };
    };
  };
}
