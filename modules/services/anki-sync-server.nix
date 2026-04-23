{
  flake.nixosModules.anki-sync-server = {
    config,
    pkgs,
    lib,
    ...
  }: {
    security.acme = {
      acceptTerms = true;
    };
    containers.anki-sync-server = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "10.0.0.7";
      localAddress = "10.0.0.8";
      config = {
        config,
        pkgs,
        lib,
        ...
      }: {
        services.anki-sync-server = {
          enable = true;
          address = "10.0.0.8";
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
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://10.0.0.8";
      };
    };
  };
}
