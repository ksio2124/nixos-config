{
  flake.nixosModules.wordpress = {
    config,
    pkgs,
    lib,
    ...
  }: {
    containers.wordpress = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "10.0.0.1";
      # hostBridge = "tap0"; # Specify the bridge name
      localAddress = "10.0.0.3";
      config = {
        config,
        pkgs,
        lib,
        ...
      }: {
        services.wordpress.sites."wordpress.cowgoesmoopiggoesoink.com" = {
          settings = {
            # Needed to run behind reverse proxy
            FORCE_SSL_ADMIN = true;
          };
          extraConfig = ''
            $_SERVER['HTTPS']='on';
          '';
          themes = {
            inherit (pkgs.wordpressPackages.themes) twentytwentyfive twentytwentyfour;
            # inherit wordpress-theme-responsive;
          };
        };
        networking.firewall.allowedTCPPorts = [80];
        system.stateVersion = "26.05"; # Required for running NixOS containers
      };
    };
    services.nginx.virtualHosts."wordpress.cowgoesmoopiggoesoink.com" = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://10.0.0.3";
      };
    };
  };
}
