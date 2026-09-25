{inputs, ...}: {
  flake.nixosModules.openclaw = {
    config,
    lib,
    ...
  }: let
    # MagicDNS name of the VM on the tailnet (headscale base_domain).
    tailnetName = "openclaw.ts.ksio2124.com";
    certDir = config.security.acme.certs.${tailnetName}.directory;
  in {
    imports = [inputs.microvm.nixosModules.host];

    # qemu runs as the microvm user and reads these itself (fw_cfg), so
    # they can't stay root-only.
    sops.secrets."openclaw/openrouterApiKey".owner = "microvm";
    sops.secrets."openclaw/gatewayAuthToken".owner = "microvm";
    # Headscale pre-auth key (tag:openclaw) for the VM's tailscale.
    sops.secrets."openclaw/tailscaleAuthKey".owner = "microvm";

    # Real cert for the tailnet name, so the Control UI is HTTPS from a
    # phone. Headscale can't issue certs for `tailscale serve`, so the host
    # gets one via Cloudflare DNS-01 (the name only resolves inside the
    # tailnet, but the _acme-challenge TXT record lives in the public
    # ksio2124.com zone) and hands it to the VM - the Cloudflare token
    # never enters the VM. Group kvm = the microvm user qemu runs as.
    security.acme.certs.${tailnetName} = {
      group = "kvm";
      dnsProvider = "cloudflare";
      credentialFiles."CLOUDFLARE_DNS_API_TOKEN_FILE" = config.sops.secrets."garage/cloudflareDnsToken".path;
      # Check propagation against Cloudflare directly: the local unbound
      # negative-caches the NXDOMAIN from before the TXT record existed.
      dnsResolver = "1.1.1.1:53";
      # Credentials are read at VM start, so a renewal needs a restart.
      reloadServices = ["microvm@openclaw.service"];
    };
    # The cert files must exist before qemu reads them.
    systemd.services."microvm@openclaw" = {
      wants = ["acme-${tailnetName}.service"];
      after = ["acme-${tailnetName}.service"];
    };

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
          TAILSCALE_AUTH_KEY = config.sops.secrets."openclaw/tailscaleAuthKey".path;
          TLS_CERT = "${certDir}/fullchain.pem";
          TLS_KEY = "${certDir}/key.pem";
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
      # 443: the VM's tailscale logs in to headscale.ksio2124.com, which
      # unbound resolves (split-horizon) to this host's nginx.
      interfaces.vm-openclaw = {
        allowedTCPPorts = [53 443];
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
