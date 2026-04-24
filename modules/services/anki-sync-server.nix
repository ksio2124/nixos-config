{
  flake.nixosModules.anki-sync-server = {config, ...}: {
    sops.secrets."anki-sync-server/password" = {};
    containers.anki-sync-server = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "10.0.0.7";
      localAddress = "10.0.0.8";
      bindMounts."/run/secrets/anki-sync-server/password" = {
        hostPath = config.sops.secrets."anki-sync-server/password".path;
      };

      config = {...}: {
        services.anki-sync-server = {
          enable = true;
          address = "10.0.0.8";
          openFirewall = true;
          users = [
            {
              username = "jack";
              passwordFile = /run/secrets/anki-sync-server/password;
            }
          ];
        };
        system.stateVersion = "26.05";
      };
    };
    services.nginx.virtualHosts."anki-sync-server.cowgoesmoopiggoesoink.com" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://10.0.0.8:27701/";
      };
    };

    security.acme.certs."anki-sync-server.cowgoesmoopiggoesoink.com".email = "ksio2124@protonmail.ch";
  };
}
