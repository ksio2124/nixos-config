{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.mailserver = {
    config,
    pkgs,
    ...
  }: {
    #
    containers.mailserver = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "10.0.0.13";
      localAddress = "10.0.0.14";
      bindMounts."/var/lib/acme/cowgoesmoopiggoesoink.com" = {
        hostPath = "/var/lib/acme/cowgoesmoopiggoesoink.com";
        isReadOnly = true;
      };

      config = {
        config,
        pkgs,
        ...
      }: {
        imports = [
          (builtins.fetchTarball {
            url = "https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/-/archive/main/nixos-mailserver-main.tar.gz";

            sha256 = "0x73hf947cky34104cfqdaqpxykvcqhykvvg1jz6wrpfakvx4ghn";
          })
        ];

        mailserver = {
          enable = true;
          stateVersion = 4;
          fqdn = "mail.cowgoesmoopiggoesoink.com";
          domains = ["cowgoesmoopiggoesoink.com"];
          x509 = {
            certificateFile = "/var/lib/acme/cowgoesmoopiggoesoink.com/fullchain.pem";
            privateKeyFile = "/var/lib/acme/cowgoesmoopiggoesoink.com/key.pem";
          };
          # certificateScheme = "manual";
          # certificateDirectory = "/var/lib/acme/cowgoesmoopiggoesoink.com";

          # x509.useACMEHost = config.mailserver.fqdn;

          accounts = {
            "user2@cowgoesmoopiggoesoink.com" = {
              hashedPassword = "$y$j9T$Ufs8vt1E9pyUSdDVITDgx.$EFBw0NCHqvec9iPYIU9lUdW1LnHHE48oA3BPnh93dAB";
            };
          };
        };

        system.stateVersion = "26.05";
      };
    };
    services.nginx.virtualHosts."cowgoesmoopiggoesoink.com" = {
      forceSSL = true;
      enableACME = true;

      locations."/" = {
        proxyPass = "http://10.0.0.14";
      };
    };
    security.acme.certs."cowgoesmoopiggoesoink.com".email = "ksio2124@protonmail.ch";
  };
}
