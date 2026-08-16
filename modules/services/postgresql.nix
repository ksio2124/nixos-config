{
  flake.nixosModules.postgresql = {config, ...}: {
    containers.postgresql = {
      autoStart = true;
      privateNetwork = true;
      hostBridge = "br-isolated";
      localAddress6 = "fdcf:4b47:cf30::10/64";
      privateUsers = "pick";
      config = {pkgs, ...}: {
        # systemd.network.networks."80-container-eth0" = {
        #   matchConfig.Name = "eth0";
        #   address = ["fdcf:4b47:cf30::10/64"];
        #   networkConfig.IPv6AcceptRA = true;
        # };
        # containers.postgres.config (or that container's own config)
        services.postgresql = {
          package = pkgs.postgresql_18;
          enable = true;
          enableTCPIP = true; # required — otherwise it only listens on the socket

          ensureDatabases = ["nextcloud"];
          ensureUsers = [
            {
              name = "nextcloud";
              ensureDBOwnership = true;
            }
          ];

          authentication = pkgs.lib.mkOverride 10 ''
            # type  database  user       address        auth-method
            local   all       all                       peer
            host    nextcloud  nextcloud  10.233.0.0/24  scram-sha-256
          '';
        };

        # open the port to the internal container network
        networking.firewall.allowedTCPPorts = [5432];
      };
    };
  };
}
