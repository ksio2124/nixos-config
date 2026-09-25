{inputs, ...}: {
  flake.nixosModules.openclaw = {
    config,
    lib,
    ...
  }: {
    imports = [inputs.microvm.nixosModules.host];

    # qemu runs as the microvm user and reads these itself (fw_cfg), so
    # they can't stay root-only.
    sops.secrets."openclaw/openrouterApiKey".owner = "microvm";
    sops.secrets."openclaw/gatewayAuthToken".owner = "microvm";

    microvm.vms.openclaw = {
      specialArgs = {inherit inputs;};
      config = {
        imports = [./_openclaw-guest.nix];

        # Decrypted on the host by sops-nix; the qemu runner hands them to
        # the guest via fw_cfg (io.systemd.credentials), where they appear
        # as /run/credentials/@system/<name> - the same "@system credential"
        # idiom the containers use with --load-credential.
        microvm.credentialFiles = {
          OPENROUTER_API_KEY = config.sops.secrets."openclaw/openrouterApiKey".path;
          GATEWAY_AUTH_TOKEN = config.sops.secrets."openclaw/gatewayAuthToken".path;
        };
      };
    };

    # The VM gets its own routed link instead of joining br-isolated: the
    # containers there trust each other (postgres 5432, headscale 8080), and
    # an agent with a shell shouldn't sit on that segment. microvm.nix
    # creates the tap when the VM starts; networkd configures it on sight.
    systemd.network.networks."30-vm-openclaw" = {
      matchConfig.Name = "vm-openclaw";
      address = [
        "192.168.4.1/24"
        "fdcf:4b47:cf30:4::1/64"
      ];
      networkConfig = {
        IPv4Forwarding = true;
        IPv6Forwarding = true;
        IPv6SendRA = true;
        DHCPPrefixDelegation = true;
        ConfigureWithoutCarrier = true;
      };
      # Public IPv6 for the VM, like br-isolated (SubnetId 2) and br0 (1).
      dhcpPrefixDelegationConfig = {
        UplinkInterface = "wan";
        SubnetId = 4;
        Assign = true;
      };
      linkConfig.RequiredForOnline = "no";
    };

    networking.firewall = {
      # Guest resolves via unbound on fdcf:4b47:cf30:4::1 (covered by
      # unbound's "::" listener and fdcf:4b47:cf30::/48 access-control).
      interfaces.vm-openclaw = {
        allowedTCPPorts = [53];
        allowedUDPPorts = [53];
      };
      # Internet only: the nat rule below lets vm-openclaw forward to wan;
      # drop everything else first (the br-isolated web/mqtt accept in
      # firewall.nix has no iifname match and would otherwise apply).
      extraForwardRules = lib.mkBefore ''
        iifname "vm-openclaw" oifname != "wan" drop comment "openclaw VM: internet only"
      '';
    };
    networking.nat.internalInterfaces = ["vm-openclaw"];
  };
}
