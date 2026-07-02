{
  flake.nixosModules.hostThemis = {
    config,
    pkgs,
    lib,
    ...
  }: {
    users.users.root = {
      subGidRanges = [
        {
          startGid = 1000000;
          count = 200000;
        }
      ];
      subUidRanges = [
        {
          startUid = 1000000;
          count = 200000;
        }
      ];
    };
    sops.secrets."cloudflare-ddns/credentials" = {};
    services.cloudflare-ddns = {
      enable = true;
      credentialsFile = config.sops.secrets."cloudflare-ddns/credentials".path;
      domains = [
        "wordpress.ksio2124.com"
        "ksio2124.com"
        "mail.ksio2124.com"
      ];
    };
    security.acme.acceptTerms = true;
    security.acme.defaults.email = "ksio2124@protonmail.ch";
  };
}
