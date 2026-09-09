{
  flake.nixosModules.hostThemis = {
    config,
    pkgs,
    lib,
    ...
  }: {
    sops.secrets."cloudflare-ddns/credentials" = {};
    services.cloudflare-ddns = {
      enable = true;
      credentialsFile = config.sops.secrets."cloudflare-ddns/credentials".path;
      domains = [
        "wordpress.ksio2124.com"
        "ksio2124.com"
      ];
      ip4Domains = ["mail.ksio2124.com" "headscale.ksio2124.com"];
      ip6Domains = ["headscale.ksio2124.com"];
    };
    security.acme.acceptTerms = true;
    security.acme.defaults.email = "ksio2124@protonmail.ch";
    security.acme.certs."mail.ksio2124.com" = {
      email = "ksio2124@protonmail.ch";
    };
    # Host nginx for ACME HTTP-01 challenge for mail subdomain
    services.nginx = {
      enable = true;
      virtualHosts."mail.ksio2124.com" = {
        enableACME = true;
        forceSSL = true;
      };
      # Host terminates TLS for headscale and forwards the decrypted
      # traffic to the container over its private br-isolated IPv6 address -
      # the container has no TLS/ACME of its own.
      virtualHosts."headscale.ksio2124.com" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://[fdcf:4b47:cf30::19]:8080";
          proxyWebsockets = true;
          recommendedProxySettings = true;
          extraConfig = ''
            proxy_read_timeout 3600s;
          '';
        };
      };
    };
  };
}
