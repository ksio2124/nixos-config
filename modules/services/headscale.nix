{
  flake.nixosModules.headscale = {...}: {
    containers.headscale = {
      autoStart = true;
      ephemeral = true;
      privateNetwork = true;
      hostBridge = "br-isolated";
      localAddress6 = "fdcf:4b47:cf30::19/64";
      privateUsers = "pick";

      extraFlags = [
        "--bind=/var/lib/headscale:/var/lib/headscale:idmap"
      ];

      config = {...}: {
        networking.nameservers = ["fdcf:4b47:cf30::1"];
        networking.useHostResolvConf = false;

        services.headscale = {
          enable = true;
          settings = {
            server_url = "https://headscale.ksio2124.com";
            # The address/port options concatenate as "${address}:${port}"
            # without bracketing, so "::" (all interfaces, IPv6) would come
            # out as ":::8080" - too many colons. Set listen_addr directly
            # with proper bracket syntax instead.
            listen_addr = "[::]:8080";
            log.level = "info";

            dns = {
              magic_dns = true;
              base_domain = "ts.ksio2124.com";
              nameservers.global = ["1.1.1.1" "1.0.0.1"];
            };

            # Use Tailscale's public DERP relays instead of self-hosting one.
            derp.server.enabled = false;
          };
        };

        # Only reachable from the isolated br-isolated network (host nginx
        # proxies in from there) - same trust model as postgres's port 5432.
        networking.firewall.allowedTCPPorts = [8080];
        system.stateVersion = "26.05"; # Required for running NixOS containers
      };
    };
  };
}
