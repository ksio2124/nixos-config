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
      bindMounts."/var/lib/acme/ksio2124.com" = {
        hostPath = "/var/lib/acme/ksio2124.com";
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
          fqdn = "mail.ksio2124.com";
          domains = ["ksio2124.com"];
          x509 = {
            certificateFile = "/var/lib/acme/ksio2124.com/fullchain.pem";
            privateKeyFile = "/var/lib/acme/ksio2124.com/key.pem";
          };
          accounts = {
            "k@ksio2124.com" = {
              hashedPassword = "y$j9T$Ufs8vt1E9pyUSdDVITDgx.$EFBw0NCHqvec9iPYIU9lUdW1LnHHE48oA3BPnh93dAB";
            };
          };
        };
        # services.postfix = {
        #   enable = true;
        #   settings.main = {
        #     relayHost = ["[live.smtp.mailtrap.io]:587"];
        #     # relayHost = "live.smtp.mailtrap.io";
        #     # relayPort = 587; # Commonly 587 for STARTTLS
        #     smtp_sasl_auth_enable = "yes";
        #     smtp_sasl_password_maps = "texthash:/etc/postfix/sasl_passwd";
        #     smtp_sasl_security_options = "noanonymous";
        #     smtp_use_tls = "yes";
        #     # smtp_tls_security_level = "encrypt"; # Ensures connections are encrypted
        #   };
        #   # relayHost = "live.smtp.mailtrap.io";
        #   # relayPort = 587; # Commonly 587 for STARTTLS
        #   # config = {
        #   #   smtp_sasl_auth_enable = "yes";
        #   #   smtp_sasl_password_maps = "texthash:/etc/postfix/sasl_passwd";
        #   #   smtp_sasl_security_options = "noanonymous";
        #   #   smtp_use_tls = "yes";
        #   #   smtp_tls_security_level = "encrypt"; # Ensures connections are encrypted
        #   # };
        # };
        #
        system.stateVersion = "26.05";
      };
    };
    services.nginx.virtualHosts."ksio2124.com" = {
      forceSSL = true;
      enableACME = true;

      locations."/" = {
        proxyPass = "http://10.0.0.14";
      };
    };
  };
}
