{
  flake.nixosModules.anki-sync-server = {config, ...}: {
    sops.secrets."anki-sync-server/password" = {};
    containers.anki-sync-server = {
      autoStart = true;
      privateNetwork = true;
      privateUsers = 66536 + 7;
      hostAddress = "10.0.0.7";
      localAddress = "10.0.0.8";
      bindMounts."/run/secrets/anki-sync-server/password" = {
        hostPath = config.sops.secrets."anki-sync-server/password".path;
      };

      config = _: {
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
    services.nginx.virtualHosts."anki-sync-server.ksio2124.com" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://10.0.0.8:27701/";
      };
    };
  };
}
