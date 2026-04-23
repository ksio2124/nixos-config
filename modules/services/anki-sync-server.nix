{
  flake.nixosModules.anki-sync-server = {...}: {
    containers.anki-sync-server = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "10.0.0.7";
      localAddress = "10.0.0.8";
      config = {...}: {
        services.anki-sync-server = {
          enable = true;
          address = "127.0.0.1";
          port = 80;
          openFirewall = true;
          users = [
            {
              username = "bob";
              password = "password";
            }
          ];
        };
        system.stateVersion = "26.05";
      };
    };
    services.nginx.virtualHosts."anki-sync-server.cowgoesmoopiggoesoink.com" = {
      # forceSSL = true;
      # enableACME = true;
      locations."/" = {
        proxyPass = "http://10.0.0.8";
      };
    };
  };
}
