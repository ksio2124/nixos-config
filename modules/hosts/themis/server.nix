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
        # nextcloud's own container has no IPv4 - the host publishes the
        # A record and reverse-proxies IPv4 traffic to the container's
        # ULA IPv6 address (see virtualHosts."nextcloud.ksio2124.com"
        # below). IPv6 clients keep going straight to the container.
        "nextcloud.ksio2124.com"
        "immich.ksio2124.com"
        "onlyoffice.ksio2124.com"
        "anki-sync-server.ksio2124.com"
        # Same for mosquitto (mqtt.ksio2124.com) - see streamConfig below.
        "mqtt.ksio2124.com"
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
    # DNS-01 instead of the default HTTP-01: nextcloud.ksio2124.com
    # already has an AAAA record pointing straight at the container
    # (its own separate cert/ACME client), so HTTP-01 validation for
    # this host-level cert would race against IPv6 being tried first
    # and land on the container's nginx instead of this host.
    security.acme.certs."nextcloud.ksio2124.com" = {
      group = "nginx";
      dnsProvider = "cloudflare";
      # Use a real external resolver for the propagation check instead of
      # the host's own unbound: unbound's local-data split-horizon
      # overrides for this same name can leave stale negative-cache
      # entries for _acme-challenge lookups, blocking renewal.
      dnsResolver = "1.1.1.1:53";
      credentialFiles."CLOUDFLARE_DNS_API_TOKEN_FILE" = config.sops.secrets."garage/cloudflareDnsToken".path;
    };
    security.acme.certs."ipv4-container-proxies" = {
      group = "nginx";
      domain = "immich.ksio2124.com";
      extraDomainNames = [
        "onlyoffice.ksio2124.com"
        "anki-sync-server.ksio2124.com"
      ];
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
      # IPv4 entry point for nextcloud (its container is IPv6-only).
      # The container already terminates its own TLS/ACME for this same
      # hostname over IPv6 - this vhost is a separate cert/entry point
      # that just relays IPv4 traffic in over the ULA address.
      virtualHosts."nextcloud.ksio2124.com" = {
        forceSSL = true;
        useACMEHost = "nextcloud.ksio2124.com";
        locations."/" = {
          proxyPass = "https://[fdcf:4b47:cf30::11]";
          proxyWebsockets = true;
          recommendedProxySettings = true;
          extraConfig = ''
            proxy_ssl_server_name on;
            client_max_body_size 200G;
            proxy_read_timeout   600s;
            proxy_send_timeout   600s;
            send_timeout         600s;
          '';
        };
      };
      # IPv4 entry points for the IPv6-only application containers.
      virtualHosts."immich.ksio2124.com" = {
        forceSSL = true;
        useACMEHost = "ipv4-container-proxies";
        locations."/" = {
          proxyPass = "https://[fdcf:4b47:cf30::13]";
          proxyWebsockets = true;
          recommendedProxySettings = true;
          extraConfig = ''
            proxy_ssl_server_name on;
            proxy_ssl_name immich.ksio2124.com;
            client_max_body_size 50000M;
            proxy_read_timeout   600s;
            proxy_send_timeout   600s;
            send_timeout         600s;
          '';
        };
      };
      virtualHosts."onlyoffice.ksio2124.com" = {
        forceSSL = true;
        useACMEHost = "ipv4-container-proxies";
        locations."/" = {
          proxyPass = "https://[fdcf:4b47:cf30::12]";
          proxyWebsockets = true;
          recommendedProxySettings = true;
          extraConfig = ''
            proxy_ssl_server_name on;
            proxy_ssl_name onlyoffice.ksio2124.com;
          '';
        };
      };
      virtualHosts."anki-sync-server.ksio2124.com" = {
        forceSSL = true;
        useACMEHost = "ipv4-container-proxies";
        locations."/" = {
          proxyPass = "https://[fdcf:4b47:cf30::14]";
          proxyWebsockets = true;
          recommendedProxySettings = true;
          extraConfig = ''
            proxy_ssl_server_name on;
            proxy_ssl_name anki-sync-server.ksio2124.com;
          '';
        };
      };
      # IPv4 entry point for mosquitto (its container is IPv6-only, same
      # as nextcloud above). MQTTS is a raw TLS stream, not HTTP, so this
      # is a plain TCP relay rather than an http reverse proxy - no host
      # cert needed, mosquitto's own cert/TLS session passes through
      # untouched all the way to the container.
      streamConfig = ''
        server {
          listen 8883;
          proxy_pass [fdcf:4b47:cf30::18]:8883;
        }
      '';
    };
  };
}
