{
  flake.nixosModules.anki-sync-server = {config, ...}: {
    sops.secrets."anki-sync-server/password" = {};
    containers.anki-sync-server = {
      autoStart = true;
      privateNetwork = true;
      privateUsers = "pick";
      ephemeral = true;
      hostBridge = "br-isolated";
      extraFlags = [
        "--load-credential=anki-sync-server-password:${config.sops.secrets."anki-sync-server/password".path}"
        "--load-credential=cloudflare-ddns-credentials:${config.sops.secrets."cloudflare-ddns/credentials".path}"
      ];
      config = _: {
        networking.useHostResolvConf = false;
        networking.nameservers = [
          "2606:4700:4700::1111"
          "2606:4700:4700::1001"
        ];
        services.cloudflare-ddns = {
          enable = true;
          credentialsFile = "/run/credentials/@system/cloudflare-ddns-credentials";
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
              passwordFile = "/run/credentials/@system/anki-sync-server-password";
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
