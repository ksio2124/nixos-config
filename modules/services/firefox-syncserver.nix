{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.firefox-syncserver = {
    config,
    pkgs,
    ...
  }: {
    containers.firefox-syncserver = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "10.0.0.11";
      localAddress = "10.0.0.10";
      # bindMounts."/run/secrets/firefox-syncserver/adminpass" = {
      #   hostPath = config.sops.secrets."firefox-syncserver/adminpass".path;
      # };
      config = {
        config,
        pkgs,
        ...
      }: {
        services.mysql.package = pkgs.mariadb;
        services.firefox-syncserver = {
          enable = true;
          secrets = builtins.toFile "sync-secrets" ''
            SYNC_MASTER_SECRET=testing
          '';
          singleNode = {
            enable = true;
            hostname = "localhost";
            url = "http://firefox-syncserver.cowgoesmoopiggoesoink.com";
          };
        };
        networking.firewall.allowedTCPPorts = [80];
        system.stateVersion = "26.05";
      };
    };
    services.nginx.virtualHosts."firefox-syncserver.cowgoesmoopiggoesoink.com" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://10.0.0.10";
      };
    };
    security.acme.certs."firefox-syncserver.cowgoesmoopiggoesoink.com".email = "ksio2124@protonmail.ch";
  };
}
