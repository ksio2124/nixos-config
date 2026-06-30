{
  flake.nixosModules.anki-sync-server = {config, ...}: {
    sops.secrets."anki-sync-server/password" = {};
    sops.secrets."cloudflare-ddns/credentials" = {};
    containers.anki-sync-server = {
      autoStart = true;
      privateNetwork = true;
      hostBridge = "br-isolated";
      bindMounts."/run/secrets/anki-sync-server/password" = {
        hostPath = config.sops.secrets."anki-sync-server/password".path;
      };
      bindMounts."/run/secrets/cloudflare-ddns/credentials" = {
        hostPath = config.sops.secrets."cloudflare-ddns/credentials".path;
      };

      config = _: {
        networking.useHostResolvConf = false;
        networking.nameservers = [
          "2606:4700:4700::1111"
          "2606:4700:4700::1001"
        ];
        services.cloudflare-ddns = {
          enable = true;
          credentialsFile = /run/secrets/cloudflare-ddns/credentials;
          ip6Domains = [
            "anki-sync-server.ksio2124.com"
          ];
        };
        services.anki-sync-server = {
          enable = true;
          address = "::1";
          openFirewall = true;
          users = [
            {
              username = "jack";
              passwordFile = /run/secrets/anki-sync-server/password;
            }
          ];
        };
        services.caddy = {
          enable = true;

          virtualHosts."anki-sync-server.ksio2124.com".extraConfig = ''
            reverse_proxy [::1]:27701
          '';
        };
        networking.firewall.allowedTCPPorts = [
          80
          443
        ];

        system.stateVersion = "26.05";
      };
    };
  };
}
