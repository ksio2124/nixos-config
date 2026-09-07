{
  flake.nixosModules.postgresql = {config, ...}: {
    containers.postgresql = {
      autoStart = true;
      privateNetwork = true;
      hostBridge = "br-isolated";
      localAddress6 = "fdcf:4b47:cf30::10/64";
      privateUsers = "pick";
      config = {pkgs, ...}: {
        system.stateVersion = "26.05"; # Required for running NixOS containers
        networking.nameservers = ["fdcf:4b47:cf30::1"];
        networking.useHostResolvConf = false;
        services.postgresql = {
          package = pkgs.postgresql_18;
          enable = true;
          enableTCPIP = true; # required — otherwise it only listens on the socket
          extensions = ps: with ps; [ps.pgvector ps.vectorchord];
          settings = {
            shared_preload_libraries = ["vchord.so"];
          };
          ensureDatabases = ["nextcloud" "onlyoffice" "immich"];
          ensureUsers = [
            {
              name = "nextcloud";
              ensureDBOwnership = true;
            }
            {
              name = "onlyoffice";
              ensureDBOwnership = true;
            }
            {
              name = "immich";
              ensureDBOwnership = true;
            }
          ];

          authentication = pkgs.lib.mkOverride 10 ''
            # type  database  user       address        auth-method
            local   all       all                       peer
            host    nextcloud  nextcloud   fdcf:4b47:cf30::11/128 scram-sha-256
            host    onlyoffice onlyoffice  fdcf:4b47:cf30::12/128 scram-sha-256
            host    immich immich  fdcf:4b47:cf30::13/128 scram-sha-256
          '';
        };

        # open the port to the internal container network
        networking.firewall.allowedTCPPorts = [5432];
      };
    };
  };
}
