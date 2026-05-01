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
    # sops.secrets."onlyoffice/adminpass" = {};
    containers.onlyoffice = {
      ephemeral = true;
      autoStart = true;
      privateUsers = "pick";
      privateNetwork = true;
      hostAddress = "10.0.0.15";
      localAddress = "10.0.0.16";
      # bindMounts."/run/secrets/onlyoffice/adminpass" = {
      #   hostPath = config.sops.secrets."onlyoffice/adminpass".path;
      # };
      # bindMounts."/mypool/onlyoffice/" = {
      #   hostPath = "/mypool/onlyoffice/";
      #   isReadOnly = false;
      # };
      config = {
        config,
        pkgs,
        ...
      }: {
        services.onlyoffice = {
          enable = true;
          hostname = "onlyoffice.cowgoesmoopiggoesoink.com";
          # jwtSecretFile = "${pkgs.writeText "onlyoffice.jwt"
          #   ''
          #     okok1234
          #   ''}";
          securityNonceFile = "${pkgs.writeText "nixos-test-onlyoffice-nonce.conf" ''

            set $secure_link_secret "nixostest";
          ''}";
        };
        networking.useHostResolvConf = false;

        # Manually set reliable public DNS servers
        networking.nameservers = ["10.0.0.15"];
        networking.firewall.allowedTCPPorts = [8000];
        system.stateVersion = "26.05";
      };
    };
    services.nginx.virtualHosts."onlyoffice.cowgoesmoopiggoesoink.com" = {
      # extraConfig = ''
      #   client_max_body_size 200G;
      #   proxy_buffering off;
      #   fastcgi_request_buffering off; # Critical for speed
      # '';
      forceSSL = true;
      enableACME = true;
      locations."/" = {
        proxyPass = "http://10.0.0.16:8000";
        extraConfig = ''
          proxy_set_header X-Forwarded-Proto https;
        '';
      };
    };

    security.acme.certs."onlyoffice.cowgoesmoopiggoesoink.com".email = "ksio2124@protonmail.ch";
  };
}
