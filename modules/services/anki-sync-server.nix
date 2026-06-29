{
  flake.nixosModules.anki-sync-server = {config, ...}: {
    sops.secrets."anki-sync-server/password" = {};
    containers.anki-sync-server = {
      autoStart = true;
      privateNetwork = true;
      privateUsers = 66536 + 7;
      hostBridge = "br-isolated";
      bindMounts."/run/secrets/anki-sync-server/password" = {
        hostPath = config.sops.secrets."anki-sync-server/password".path;
      };

      config = _: {
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
        system.stateVersion = "26.05";
      };
    };
  };
}
