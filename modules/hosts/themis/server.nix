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
      ip4Domains = [
        "mail.ksio2124.com"
        "headscale.ksio2124.com"
        "s3-api.ksio2124.com"
        "s3-web.ksio2124.com"
        "*.s3-web.ksio2124.com"
      ];
      ip6Domains = [
        "headscale.ksio2124.com"
        "s3-api.ksio2124.com"
        "s3-web.ksio2124.com"
        "*.s3-web.ksio2124.com"
      ];
    };
    security.acme.acceptTerms = true;
    security.acme.defaults.email = "ksio2124@protonmail.ch";
    security.acme.certs."mail.ksio2124.com" = {
      email = "ksio2124@protonmail.ch";
    };
    security.acme.certs."s3-web.ksio2124.com" = {
      group = "nginx";
      domain = "*.s3-web.ksio2124.com";
      extraDomainNames = ["s3-web.ksio2124.com"];
      dnsProvider = "cloudflare";
      credentialFiles."CLOUDFLARE_DNS_API_TOKEN_FILE" = config.sops.secrets."garage/cloudflareDnsToken".path;
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
      virtualHosts."s3-api.ksio2124.com" = {
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://[fdcf:4b47:cf30::17]:3900";
          recommendedProxySettings = true;
          extraConfig = ''
            client_max_body_size 5000M;
            proxy_read_timeout   600s;
            proxy_send_timeout   600s;
            send_timeout         600s;
          '';
        };
      };
      virtualHosts."s3-web.ksio2124.com" = {
        serverAliases = ["*.s3-web.ksio2124.com"];
        forceSSL = true;
        useACMEHost = "s3-web.ksio2124.com";
        locations."/" = {
          proxyPass = "http://[fdcf:4b47:cf30::17]:3902";
          recommendedProxySettings = true;
        };
      };
    };
  };
}
