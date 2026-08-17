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
    sops.secrets."onlyoffice/postgresqlpass" = {};
    sops.secrets."onlyoffice/jwtSecret" = {};
    containers.onlyoffice = {
      ephemeral = true;
      autoStart = true;
      privateUsers = "pick";
      privateNetwork = true;
      hostBridge = "br-isolated";
      localAddress6 = "fdcf:4b47:cf30::12/64";
      extraFlags = [
        "--load-credential=cloudflare-ddns-credentials:${config.sops.secrets."cloudflare-ddns/credentials".path}"
        "--load-credential=onlyoffice-postgresqlpass:${config.sops.secrets."onlyoffice/postgresqlpass".path}"
        "--load-credential=onlyoffice-jwtSecret:${config.sops.secrets."onlyoffice/jwtSecret".path}"
        "--load-credential=onlyoffice-securityNonce:${config.sops.secrets."onlyoffice/securityNonce".path}"
      ];
      config = {
        config,
        pkgs,
        ...
      }: {
        systemd.services.onlyoffice-docservice.serviceConfig.LoadCredential = [
          "onlyoffice-securityNonce:/run/credentials/@system/onlyoffice-securityNonce"
          "onlyoffice-jwtSecret:/run/credentials/@system/onlyoffice-jwtSecret"
          "onlyoffice-postgresqlpass:/run/credentials/@system/onlyoffice-postgresqlpass"
        ];
        services.onlyoffice = {
          enable = true;
          hostname = "onlyoffice.ksio2124.com";
          rabbitmqUrl = "amqp://guest:guest@127.0.0.1:5672";
          securityNonceFile = "/run/credentials/onlyoffice-docservice.service/onlyoffice-securityNonce";
          jwtSecretFile = "/run/credentials/onlyoffice-docservice.service/onlyoffice-jwtSecret";
          postgresPasswordFile = "/run/credentials/onlyoffice-docservice.service/onlyoffice-postgresqlpass";
          # securityNonceFile = "/run/credentials/@system/onlyoffice-securityNonce";
          # jwtSecretFile = "/run/credentials/@system/onlyoffice-jwtSecret";
          postgresHost = "postgresql.home";
          # postgresPasswordFile = "/run/credentials/@system/onlyoffice-postgresqlpass";
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
            "testing.ksio2124.com"
          ];
        };
      };
    };
  };
}
