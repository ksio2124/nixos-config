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
    sops.secrets."onlyoffice/securityNonce" = {};
    sops.secrets."onlyoffice/jwtSecret" = {};
    containers.onlyoffice = {
      # ephemeral = true;
      autoStart = true;
      privateUsers = "pick";
      privateNetwork = true;
      hostBridge = "br-isolated";
      localAddress6 = "fdcf:4b47:cf30::12/64";
      extraFlags = [
        "--load-credential=cloudflare-ddns-credentials:${config.sops.secrets."cloudflare-ddns/credentials".path}"
        "--load-credential=onlyoffice-jwtSecret:${config.sops.secrets."onlyoffice/jwtSecret".path}"
        "--load-credential=onlyoffice-securityNonce:${config.sops.secrets."onlyoffice/securityNonce".path}"
      ];
      config = {
        config,
        pkgs,
        ...
      }: {
        users.groups.onlyoffice-secrets = {};
        users.users.nginx.extraGroups = ["onlyoffice-secrets"];
        users.users.onlyoffice.extraGroups = ["onlyoffice-secrets"];

        systemd.tmpfiles.rules = [
          "d /run/onlyoffice-secrets 0750 root onlyoffice-secrets -"
          "C /run/onlyoffice-secrets/securityNonce 0640 root onlyoffice-secrets - /run/credentials/@system/onlyoffice-securityNonce"
          "C /run/onlyoffice-secrets/jwtSecret 0640 root onlyoffice-secrets - /run/credentials/@system/onlyoffice-jwtSecret"
        ];
        services.onlyoffice = {
          enable = true;
          hostname = "onlyoffice.ksio2124.com";
          rabbitmqUrl = "amqp://guest:guest@127.0.0.1:5672";
          securityNonceFile = "/run/onlyoffice-secrets/securityNonce";
          jwtSecretFile = "/run/onlyoffice-secrets/jwtSecret";
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
