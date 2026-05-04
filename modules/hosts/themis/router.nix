{
  flake.nixosModules.hostThemis = {
    pkgs,
    lib,
    config,
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
      };
      "10-lan1" = {
        matchConfig.MACAddress = "10:e7:c6:32:a1:72";
        linkConfig.Name = "lan1";
      };
      "10-lan2" = {
        matchConfig.MACAddress = "00:10:18:e5:16:93";
        linkConfig.Name = "lan2";
      };
      "10-lan3" = {
        matchConfig.MACAddress = "00:10:18:e5:16:92";
        linkConfig.Name = "lan3";
      };
      "10-lan4" = {
        matchConfig.MACAddress = "00:10:18:e5:16:91";
        linkConfig.Name = "lan4";
      };
      "10-lan5" = {
        matchConfig.MACAddress = "00:10:18:e5:16:90";
        linkConfig.Name = "lan5";
      };
    };

    systemd.network.netdevs."20-br0" = {
      netdevConfig = {
        Kind = "bridge";
        Name = "br0";
        MACAddress = "02:07:a0:53:88:4d";
      };
    };

    # 4. Bind LAN interfaces to the Bridge
    systemd.network.networks = {
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
        dhcpServerConfig = {
          EmitDNS = true;
          PoolOffset = 50;
          DNS = ["1.1.1.1" "8.8.8.8"];
        };
        ipv6SendRAConfig = {
          # Managed = false; # Set 'true' only if using Kea/DHCPv6
          # OtherInformation = true;
          EmitDNS = true;
          DNS = ["_linklocal"];
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
        dhcpV6Config.WithoutRA = "solicit";
        # Security: Don't let the WAN tell us to change our DNS
        dhcpV4Config.UseDNS = false;
        dhcpV6Config.UseDNS = false;
      };
    };

    sops.secrets."wireguard/PrivateKey" = {
      owner = "systemd-network";
      group = "systemd-network";
    };
    systemd.network = {
      networks."50-wg0" = {
        matchConfig.Name = "wg0";

        address = [
          # /32 and /128 specifies a single address
          # for use on this wg peer machine
          "fd31:bf08:57cb::7/128"
          "192.168.2.1/32"
        ];
      };

      netdevs."50-wg0" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg0";
        };

        wireguardConfig = {
          ListenPort = 51820;

          # ensure file is readable by `systemd-network` user
          PrivateKeyFile = config.sops.secrets."wireguard/PrivateKey".path;

          # To automatically create routes for everything in AllowedIPs,
          # add RouteTable=main
          RouteTable = "main";

          # FirewallMark marks all packets send and received by wg0
          # with the number 42, which can be used to define policy rules on these packets.
          FirewallMark = 42;
        };
        wireguardPeers = [
          {
            # xieshi
            PublicKey = "/mmnnC+MQiUcIBbSCmsqbDWqFIaOa6AnVj2c9PWgjBg=";
            AllowedIPs = [
              "fd31:bf08:57cb::8/128"
              "192.168.2.2/32"
            ];
          }
        ];
      };
    };

    services.resolved.enable = false;
    #
    # services.kea.dhcp4 = {
    #   enable = true;
    #   settings = {
    #     interfaces-config = {
    #       interfaces = ["br0"];
    #       service-sockets-max-retries = 20;
    #     };
    #
    #     lease-database = {
    #       type = "memfile";
    #       persist = true;
    #       name = "/var/lib/kea/kea-leases4.csv";
    #     };
    #
    #     # Replicating dnsmasq dhcp-range and options
    #     subnet4 = [
    #       {
    #         id = 1;
    #         subnet = "192.168.1.0/24";
    #         pools = [
    #           {pool = "192.168.1.10 - 192.168.1.254";}
    #         ];
    #
    #         # Replicating "5m" lease time
    #         valid-lifetime = 300;
    #
    #         option-data = [
    #           {
    #             # dhcp-option 3 (Router)
    #             name = "routers";
    #             data = "192.168.1.1";
    #           }
    #           {
    #             # dhcp-option 6 (DNS) - Pointing to your local address 10.0.0.1
    #             name = "domain-name-servers";
    #             data = "192.168.1.1";
    #           }
    #           {
    #             # Replicating 'domain = example.com'
    #             name = "domain-name";
    #             data = "example.com";
    #           }
    #         ];
    #       }
    #     ];
    #   };
    # };
    #
    boot.kernel.sysctl = {
      "net.core.rmem_max" = 4194304; # 4MB
      "net.core.wmem_max" = 4194304; # 4MB
      "net.core.netdev_max_backlog" = 25000;
      "net.ipv4.tcp_fastopen" = 3;
      "net.core.busy_poll" = 1;
    };
    services.unbound = {
      enable = true;
      # blocklist.enable = true;
      settings = {
        server = {
          # Port for Unbound to listen for local clients (plain DNS)
          interface = [
            "127.0.0.1"
            "::1"
            "192.168.1.1"
            "10.0.0.15"
            "10.88.0.1" #podman port
            # "fe80::/10"
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
            "10.0.0.0/8 allow"
            "::1 allow"
            "192.168.1.0/24 allow" # Replace with your local subnet
            "fe80::/10 allow"
            "0.0.0.0/0 refuse" # Block everyone else
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
    networking.firewall.enable = false;
    networking.nftables = {
      enable = true;
      rulesetFile = ./firewall.nft;
    };
  };
}
