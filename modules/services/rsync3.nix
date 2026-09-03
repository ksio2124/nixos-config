{
  flake.nixosModules.rsync3 = {config, ...}: {
    containers.rsync3 = {
      autoStart = true;
      #ephemeral = true;
      privateNetwork = true;
      hostBridge = "br-isolated";
      localAddress6 = "fdcf:4b47:cf30::16/64";
      privateUsers = "pick";
      extraFlags = [
        "--load-credential=cloudflare-ddns-credentials:${config.sops.secrets."cloudflare-ddns/credentials".path}"
        "--bind=/mypool/rsync:/home:idmap"
      ];
      config = {
        config,
        pkgs,
        ...
      }: {
        nixpkgs.config.allowUnfree = true;
        environment.systemPackages = [
          pkgs.rsync
        ];
        networking.nameservers = ["fdcf:4b47:cf30::1"];
        users.users.phi = {
          isNormalUser = true;
        };
        services.openssh = {
          enable = true;
          settings = {
            PermitRootLogin = "no";
            AllowUsers = ["phi"];
          };
        };
        services.tailscale.enable = true;
        networking.nftables.enable = true;
        networking.firewall = {
          enable = true;
          # Always allow traffic from your Tailscale network
          trustedInterfaces = [config.services.tailscale.interfaceName];
          # Allow the Tailscale UDP port through the firewall
          allowedUDPPorts = [config.services.tailscale.port];
        };

        # 2. Force tailscaled to use nftables (Critical for clean nftables-only systems)
        # This avoids the "iptables-compat" translation layer issues.
        systemd.services.tailscaled.serviceConfig.Environment = [
          "TS_DEBUG_FIREWALL_MODE=nftables"
        ];

        networking.useHostResolvConf = false;
        # system.useHostResolvConf

        # Prevent the host from overwriting resolv.conf with its own potentially invalid one

        system.stateVersion = "25.05"; # Required for running NixOS containers
      };
    };
  };
}
