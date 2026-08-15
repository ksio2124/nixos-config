{
  flake.nixosModules.postgresql = {config, ...}: {
    containers.postgresql = {
      autoStart = true;
      privateNetwork = true;
      hostBridge = "br-isolated";
      privateUsers = "pick";
      config = {
        config,
        pkgs,
        ...
      }: {
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
            host    nextcloud  nextcloud  10.233.x.0/24  scram-sha-256
          '';
        };

        # open the port to the internal container network
        networking.firewall.allowedTCPPorts = [5432];
      };
    };
  };
}
