{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.mailserver = {
    config,
    pkgs,
    lib,
    ...
  }: {
    sops.secrets."mailserver/hashedPasswordFile/k" = {};
    containers.mailserver = {
      autoStart = true;
      privateNetwork = true;
      hostAddress = "10.0.0.13";
      localAddress = "10.0.0.14";
      privateUsers = "pick";
      extraFlags = [
        "--load-credential=mailserver-hashedPasswordFile-k:${config.sops.secrets."mailserver/hashedPasswordFile/k".path}"
        "--bind=/mypool/mailserver/vmail:/mypool/mailserver/vmail:idmap"
        "--bind=/mypool/mailserver/dkim:/mypool/mailserver/dkim:idmap"
        "--bind=/mypool/mailserver/dovecot:/mypool/mailserver/dovecot:idmap"
        "--bind-ro=/var/lib/acme/mail.ksio2124.com:/var/lib/acme/mail.ksio2124.com:idmap"
      ];

      config = {
        config,
        pkgs,
        lib,
        ...
      }: {
        imports = [
          inputs.nixos-mailserver.nixosModules.mailserver
        ];

        # Container networking
        networking.useHostResolvConf = false;
        networking.nameservers = ["10.0.0.13"];
        networking.firewall = {
          enable = true;
          allowedTCPPorts = [
            25
            465
            587
            993
            995
          ];
        };
        systemd.tmpfiles.rules = [
          "d /run/mailserver-secrets 0750 root root -"
          "C /run/mailserver-secrets/hashedPasswordFile-k 0444 root root - /run/credentials/@system/mailserver-hashedPasswordFile-k"
        ];

        # System
        system.stateVersion = "25.05";
        time.timeZone = "America/Los_Angeles";

        # Mailserver configuration
        mailserver = {
          enable = true;
          stateVersion = 5;
          fqdn = "mail.ksio2124.com";
          domains = ["ksio2124.com"];

          # Use ACME certs from host (bind-mounted)
          x509 = {
            certificateFile = "/var/lib/acme/mail.ksio2124.com/fullchain.pem";
            privateKeyFile = "/var/lib/acme/mail.ksio2124.com/key.pem";
          };

          # DKIM signing
          dkim = {
            enable = true;
            keyDirectory = "/mypool/mailserver/dkim";
            defaults.selector = "mail";
          };
          # dkimSigning = true;
          # dkimSelector = "mail";
          # dkimKeyDirectory = "/mypool/mailserver/dkim";

          # External storage paths
          storage = {
            path = "/mypool/mailserver/vmail";
            uid = 5000;
            gid = 5000;
            owner = "virtualMail";
            group = "virtualMail";
          };

          # Dovecot index directory
          indexDir = "/mypool/mailserver/dovecot";

          # Accounts
          # loginAccounts = {
          #   "k@ksio2124.com" = {
          #     hashedPasswordFile = "/run/credentials/@system/mailserver-hashedPasswordFile-k";
          #   };
          # };
          accounts = {
            "k@ksio2124.com" = {
              hashedPasswordFile = "/run/mailserver-secrets/hashedPasswordFile-k";
            };
          };

          # Enable recommended protocols
          enableSubmissionSsl = true; # Port 465
          enableImapSsl = true; # Port 993

          # System contact
          systemContact = "postmaster@ksio2124.com";
        };
        # systemd.services.containers-mailserver = {
        #   requires = ["acme-mail.ksio2124.com.service"];
        #   after = [
        #     "nginx.service"
        #     "acme-mail.ksio2124.com.service"
        #   ];
        # };
      };
    };
  };
}
