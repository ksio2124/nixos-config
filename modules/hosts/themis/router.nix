{
  inputs,
  self,
  ...
}: {
  flake.nixosModules.hostThemis = {
    pkgs,
    lib,
    ...
  }: {
    # tested somehow i needed this?
    boot.kernel.sysctl = {
      "net.ipv4.conf.all.forwarding" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
    # 1. Disable high-level networking abstractions
    networking.usePredictableInterfaceNames = false;
    networking.useDHCP = false; # We will define this per-interface
    networking.useNetworkd = true;
    networking.networkmanager.enable = lib.mkForce false;
    systemd.network.enable = true;
    systemd.network.links = {
      "10-wan" = {
        matchConfig.MACAddress = "00:e0:ed:93:e5:58";
        linkConfig.Name = "wan";
        linkConfig.MTUBytes = 9000;
        linkConfig.TransmitQueueLength = 1000;
        linkConfig = {
          RxBufferSize = 4096;
          TxBufferSize = 4096;
        };
      };
      "10-lan0" = {
        matchConfig.MACAddress = "00:e0:ed:93:e5:59";
        linkConfig.Name = "lan0";
        # X550 (ixgbe), same chip as wan: hardware max is 4096/4096,
        # but only defaults to 512/512 unless set explicitly.
        linkConfig = {
          RxBufferSize = 4096;
          TxBufferSize = 4096;
        };
      };
      "10-lan1" = {
        matchConfig.MACAddress = "10:e7:c6:32:a1:72";
        linkConfig.Name = "lan1";
        # Onboard I219-LM (e1000e): hardware max is 4096/4096,
        # defaults to 256/256.
        linkConfig = {
          RxBufferSize = 4096;
          TxBufferSize = 4096;
        };
      };
      "10-lan2" = {
        matchConfig.MACAddress = "00:10:18:e5:16:93";
        linkConfig.Name = "lan2";
        # BCM5719 (tg3): hardware max is RX 2047 / TX 511,
        # RX defaults to 200 leaving most of the ring unused.
        # Also bump RX/TX queue count from the tg3 default (3/1) to
        # its max (4/4) so TX processing isn't pinned to one core.
        linkConfig = {
          RxBufferSize = 2047;
          TxBufferSize = 511;
          RxChannels = 4;
          TxChannels = 4;
        };
      };
      "10-lan3" = {
        matchConfig.MACAddress = "00:10:18:e5:16:92";
        linkConfig.Name = "lan3";
        linkConfig = {
          RxBufferSize = 2047;
          TxBufferSize = 511;
          RxChannels = 4;
          TxChannels = 4;
        };
      };
      "10-lan4" = {
        matchConfig.MACAddress = "00:10:18:e5:16:91";
        linkConfig.Name = "lan4";
        linkConfig = {
          RxBufferSize = 2047;
          TxBufferSize = 511;
          RxChannels = 4;
          TxChannels = 4;
        };
      };
      "10-lan5" = {
        matchConfig.MACAddress = "00:10:18:e5:16:90";
        linkConfig.Name = "lan5";
        linkConfig = {
          RxBufferSize = 2047;
          TxBufferSize = 511;
          RxChannels = 4;
          TxChannels = 4;
        };
      };
    };

    systemd.network.netdevs = {
      "20-br0" = {
        netdevConfig = {
          Kind = "bridge";
          Name = "br0";
          MACAddress = "02:07:a0:53:88:4d";
        };
      };
      "20-br-isolated" = {
        netdevConfig = {
          Name = "br-isolated";
          Kind = "bridge";
        };
      };
    };

    # 4. Bind LAN interfaces to the Bridge
    systemd.network.networks = {
      "20-br-isolated" = {
        matchConfig.Name = "br-isolated";
        address = [
          "192.168.2.1/24"
          "fdcf:4b47:cf30::1/64"
        ];

        networkConfig = {
          # IMPORTANT: NO IPv4 here
          IPv4Forwarding = true;
          IPv6Forwarding = true;
          DHCPServer = true;
          IPv6SendRA = true;
          IPv6PrivacyExtensions = "yes";
          ConfigureWithoutCarrier = true;
          DHCPPrefixDelegation = true;
        };
        dhcpServerConfig = {
          EmitDNS = true;
          PoolOffset = 50;
          PoolSize = 150;

          DNS = [
            "192.168.2.1"
          ];
        };

        dhcpPrefixDelegationConfig = {
          UplinkInterface = "wan";
          SubnetId = 2;
          Assign = true;
        };

        ipv6SendRAConfig = {
          EmitDNS = true;
          DNS = ["_link_local"];
        };
      };
      # The mailserver container uses a point-to-point veth (hostAddress/
      # localAddress) that nixos-container configures itself. Without this,
      # systemd's stock 80-container-ve.network claims ve-mailserver and, on
      # any networkd reload, flushes the 10.0.0.13 address and the route to
      # 10.0.0.14, leaving the container unreachable.
      "10-ve-mailserver" = {
        matchConfig.Name = "ve-mailserver";
        linkConfig.Unmanaged = true;
      };
      "30-lan-to-bridge" = {
        # Matches any interface named LAN0 through LAN5
        matchConfig.Name = "lan*";
        networkConfig.Bridge = "br0";
        networkConfig.ConfigureWithoutCarrier = true;
        linkConfig.RequiredForOnline = "enslaved";
      };

      # 5. Configure the Bridge IP
      "40-br0" = {
        matchConfig.Name = "br0";
        address = ["192.168.1.1/24"];
        networkConfig = {
          IPv4Forwarding = true;
          IPv6Forwarding = true;
          ConfigureWithoutCarrier = true;
          IPv6SendRA = true;
          DHCPPrefixDelegation = true;
          IPv6PrivacyExtensions = "yes";
          DHCPServer = true;
        };
        dhcpPrefixDelegationConfig = {
          UplinkInterface = "wan";
          SubnetId = 1;
          Assign = true;
        };
        dhcpServerConfig = {
          EmitDNS = true;
          PoolOffset = 50;
          DNS = ["192.168.1.1"];
        };
        ipv6SendRAConfig = {
          # Managed = false; # Set 'true' only if using Kea/DHCPv6
          # OtherInformation = true;
          EmitDNS = true;
          DNS = ["_link_local"];
          # Autonomous = true;
        };
        linkConfig.RequiredForOnline = "no";
      };

      # 6. Configure WAN (DHCP)
      "40-wan" = {
        matchConfig.Name = "wan";
        networkConfig = {
          DHCP = "yes";
          IPv4Forwarding = true;
          IPv6Forwarding = true;
          IPv6AcceptRA = true;
        };
        dhcpV6Config = {
          WithoutRA = "solicit";
          PrefixDelegationHint = "::/56"; # Sonic defaults to a /56 allocation block
          DUIDType = "vendor"; # Forces standard DUID generation for Sonic's platform compatibility
          UseDNS = false;
        };
        # Security: Don't let the WAN tell us to change our DNS
        dhcpV4Config.UseDNS = false;
      };
    };

    services.resolved.enable = false;
    boot.kernel.sysctl = {
      "net.core.rmem_max" = 4194304; # 4MB
      "net.core.wmem_max" = 4194304; # 4MB
      "net.core.netdev_max_backlog" = 25000;
      "net.ipv4.tcp_fastopen" = 3;
      "net.core.busy_poll" = 1;
      # Default NAPI poll budget (300 packets / 8000us) is tuned for a
      # single-NIC host; this box services 6 physical interfaces
      # (wan, lan0-5) concurrently doing bridged/routed forwarding.
      "net.core.netdev_budget" = 600;
      "net.core.netdev_budget_usecs" = 8000;
      # Safety net for the 9000-byte jumbo MTU on wan: falls back
      # cleanly if any hop on the path doesn't actually pass jumbo
      # frames, instead of black-holing.
      "net.ipv4.tcp_mtu_probing" = 1;
    };
    services.unbound = {
      enable = true;
      settings = {
        server = {
          # Port for Unbound to listen for local clients (plain DNS)
          interface = [
            "127.0.0.1"
            "::1"
            "192.168.1.1"
            "192.168.2.1"
            "10.0.0.13"
            "::"
          ];
          include = [
            "${inputs.hosts.packages.${pkgs.stdenv.hostPlatform.system}.unbound}/fakenews-gambling-porn"
          ];
          local-zone = [
            ''"home." static''
            # Without this, unbound treats nextcloud.ksio2124.com as
            # authoritative for the whole name once any local-data exists
            # for it: NODATA for other record types (broke the A record
            # above) and NXDOMAIN for subdomains (broke the ACME DNS-01
            # _acme-challenge.nextcloud.ksio2124.com TXT lookup lego uses
            # to verify propagation). "transparent" keeps the local A/AAAA
            # overrides but forwards everything else normally.
            ''"nextcloud.ksio2124.com." transparent''
            # Same reasoning as nextcloud above, applied up front this
            # time since we know both A and AAAA local-data are needed.
            ''"mqtt.ksio2124.com." transparent''
          ];
          local-data = [
            ''"postgresql.home. IN AAAA fdcf:4b47:cf30::10"''
            ''"nextcloud.home. IN AAAA fdcf:4b47:cf30::11"''
            ''"immich.home. IN AAAA fdcf:4b47:cf30::13"''
            ''"mail.ksio2124.com. IN A 10.0.0.14"''
            # Split-horizon: without this, LAN clients resolve the public
            # AAAA (kept current by cloudflare-ddns) and try to reach
            # themis via its own WAN address, which fails with "No route
            # to host" (no hairpin NAT/routing back in over wan). Serve
            # the internal address directly instead, same as mail above.
            ''"nextcloud.ksio2124.com. IN AAAA fdcf:4b47:cf30::11"''
            # A-only local-data above (mail) works because that name has
            # no AAAA at all, but adding *only* an AAAA override here made
            # unbound answer authoritatively (NODATA) for A queries too,
            # hiding the real public A record cloudflare-ddns publishes.
            # Point A at the host itself (which now reverse-proxies IPv4
            # to the container over its ULA address) instead of leaving
            # it to resolve publicly and hairpin the same way AAAA did.
            ''"nextcloud.ksio2124.com. IN A 192.168.1.1"''
            # Same split-horizon pattern for mosquitto: AAAA -> container
            # directly, A -> host, which relays IPv4 to the container via
            # streamConfig (see server.nix).
            ''"mqtt.ksio2124.com. IN AAAA fdcf:4b47:cf30::18"''
            ''"mqtt.ksio2124.com. IN A 192.168.1.1"''
          ];
          # Required for DoT upstreams
          tls-cert-bundle = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          # --- Performance & Threading ---
          # Match this to your physical CPU cores
          num-threads = 12;

          # Optimizing slabs to reduce lock contention (should be a power of 2 near num-threads)
          msg-cache-slabs = 8;
          rrset-cache-slabs = 8;
          infra-cache-slabs = 8;
          key-cache-slabs = 8;

          # Cache sizes (Typical rule: RRset is 2x Message cache)
          # Increase these for busy networks (e.g., 512m and 1g)
          msg-cache-size = "128m";
          rrset-cache-size = "256m";

          # Networking tweaks
          so-rcvbuf = "4m";
          so-reuseport = "yes"; # Improves UDP performance on Linux
          prefetch = "yes"; # Refreshes popular records before they expire
          prefetch-key = "yes"; # Prefetch DNSSEC keys for faster validation

          # --- Security & Privacy ---
          # Prevent unauthorized access
          access-control = [
            "127.0.0.0/8 allow"
            "::1 allow"
            "192.168.2.0/24 allow"
            "192.168.1.0/24 allow"
            "10.0.0.0/24 allow"
            "fe80::/10 allow"
            "fdcf:4b47:cf30::/48 allow"
            "0.0.0.0/0 refuse"
            "::/0 refuse"
          ];

          # Hardening the resolver
          harden-glue = "yes";
          harden-dnssec-stripped = "yes";
          harden-below-nxdomain = "yes";
          harden-referral-path = "yes";

          # Privacy tweaks
          qname-minimisation = "yes"; # Only sends necessary info to upstream
          hide-identity = "yes";
          hide-version = "yes";
          use-caps-for-id = "yes"; # Adds randomness to prevent spoofing

          # Rebinding protection (prevent local service hijacking)
          private-address = [
            "10.0.0.0/8"
            "172.16.0.0/12"
            "192.168.0.0/16"
            "169.254.0.0/16"
            "fd00::/8"
            "fe80::/10"
          ];
        };
        forward-zone = [
          {
            name = ".";
            forward-tls-upstream = "yes";
            # Cloudflare DoT servers
            forward-addr = [
              "2606:4700:4700::1111@853#cloudflare-dns.com"
              "2606:4700:4700::1001@853#cloudflare-dns.com"
              "1.1.1.1@853#cloudflare-dns.com"
              "1.0.0.1@853#cloudflare-dns.com"
            ];
          }
        ];
      };
    };
    services.avahi = {
      enable = true;
      allowInterfaces = ["br0"];
      nssmdns6 = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
    };

    networking.firewall.enable = false;
    networking.nftables = {
      enable = true;
      rulesetFile = ./firewall.nft;
    };
  };
}
