{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.mailserver2 = {
    config,
    pkgs,
    ...
  }: {
    users.users.mailserver2 = {
      uid = 66536 + 18;
      isSystemUser = true;
      group = "mailserver2";
    };
    users.groups.mailserver2.gid = 66536 + 18;
    sops.secrets."mailtrap/api_token" = {
      owner = "mailserver2";
    };
    systemd.tmpfiles.rules = [
      # Type | Path            | Mode | User        | Group       | Age | Argument
      "d      /mypool/mailserver2/vmail     0700   0   70554   -     -"
      "d      /mypool/mailserver2/lib/postfix     0700   0   70554   -     -"
      "d      /mypool/mailserver2/lib/dovecot     0700   0   70554   -     -"
    ];
    containers.mailserver = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "10.0.0.17";
      localAddress = "10.0.0.18";
      ephemeral = true;
      # privateUsers = 65536 + 18;
      bindMounts = {
        "/var/lib/acme/cowgoesmoopiggoesoink.com" = {
          hostPath = "/var/lib/acme/cowgoesmoopiggoesoink.com";
          isReadOnly = true;
        };
        "/var/vmail".hostPath = "/mypool/mailserver2/vmail";
        "/var/lib/postfix".hostPath = "/mypool/mailserver2/lib/postfix";
        "/var/lib/dovecot".hostPath = "/mypool/mailserver2/lib/dovecot";
      };

      config = {...}: {
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
        proxyPass = "http://10.0.0.18";
      };
    };
    security.acme.certs."cowgoesmoopiggoesoink.com".email = "ksio2124@protonmail.ch";
  };
}
