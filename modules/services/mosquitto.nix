{
  flake.nixosModules.mosquitto = {config, ...}: {
    sops.secrets."mosquitto/ks/password" = {};
    sops.secrets."mosquitto/in/password" = {};
    sops.secrets."mosquitto/cs/password" = {};

    containers.mosquitto = {
      autoStart = true;
      ephemeral = true;
      privateNetwork = true;
      hostBridge = "br-isolated";
      localAddress6 = "fdcf:4b47:cf30::18/64";
      privateUsers = "pick";

      extraFlags = [
        "--load-credential=cloudflare-ddns-credentials:${config.sops.secrets."cloudflare-ddns/credentials".path}"
        "--load-credential=mosquitto-ks-password:${config.sops.secrets."mosquitto/ks/password".path}"
        "--load-credential=mosquitto-in-password:${config.sops.secrets."mosquitto/in/password".path}"
        "--load-credential=mosquitto-cs-password:${config.sops.secrets."mosquitto/cs/password".path}"
        "--bind=/mypool/mosquitto/data:/mypool/mosquitto/data:idmap"
        "--bind=/var/lib/acme/mosquitto:/var/lib/acme:idmap"
      ];

      config = {...}: {
        networking.nameservers = ["fdcf:4b47:cf30::1"];
        networking.useHostResolvConf = false;
        networking.firewall.allowedTCPPorts = [80 8883];

        services.cloudflare-ddns = {
          enable = true;
          credentialsFile = "/run/credentials/@system/cloudflare-ddns-credentials";
          ip6Domains = ["mqtt.ksio2124.com"];
        };

        security.acme = {
          acceptTerms = true;
          defaults.email = "ksio2124@protonmail.ch";
          certs."mqtt.ksio2124.com" = {
            group = "mosquitto";
            # No nginx needed - lego answers the HTTP-01 challenge itself.
            listenHTTP = ":80";
          };
        };

        services.mosquitto = {
          enable = true;
          dataDir = "/mypool/mosquitto/data";
          listeners = [
            {
              port = 8883;
              address = "::";
              # fullchain.pem (leaf + intermediate), not cert.pem (leaf
              # only) - clients need the intermediate to build a trust
              # path back to a root they already have. cafile is not
              # needed since we don't verify client certs.
              settings.certfile = "/var/lib/acme/mqtt.ksio2124.com/fullchain.pem";
              settings.keyfile = "/var/lib/acme/mqtt.ksio2124.com/key.pem";
              users = {
                ks.passwordFile = "/run/credentials/@system/mosquitto-ks-password";
                "in".passwordFile = "/run/credentials/@system/mosquitto-in-password";
                cs.passwordFile = "/run/credentials/@system/mosquitto-cs-password";
              };
              # Any authenticated user may publish only to their own
              # owntracks/<username>/# topic, but may read everyone's, so
              # OwnTracks' "Friends" map shows all 3 users.
              acl = [
                "pattern write owntracks/%u/#"
                "pattern read owntracks/#"
              ];
            }
          ];
        };

        system.stateVersion = "26.05"; # Required for running NixOS containers
      };
    };
  };
}
