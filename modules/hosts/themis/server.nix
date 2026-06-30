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
        "mail.ksio2124.com"
      ];
    };
    security.acme.acceptTerms = true;
    security.acme.defaults.email = "ksio2124@protonmail.ch";
  };
}
