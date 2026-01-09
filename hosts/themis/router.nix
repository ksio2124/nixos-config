{
  config,
  pkgs,
  lib,
  ...
}:

{
  networking.usePredictableInterfaceNames = false;
  services = {
    # bottom 10g is set to wan
    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="00:e0:ed:93:e5:58", NAME="WAN"
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="00:e0:ed:93:e5:59", NAME="LAN0"
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="10:e7:c6:32:a1:72", NAME="LAN1"
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="00:10:18:e5:16:93", NAME="LAN2"
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="00:10:18:e5:16:92", NAME="LAN3"
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="00:10:18:e5:16:91", NAME="LAN4"
      ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="00:10:18:e5:16:90", NAME="LAN5"
    '';
  };
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = 1;
  };
  networking = {
    networkmanager.enable = lib.mkForce false;
    useNetworkd = true;
    bridges = {
      br0 = {
        interfaces = [
          "LAN0"
          "LAN1"
          "LAN2"
          "LAN3"
          "LAN4"
          "LAN5"
        ];
      };
    };
    # Of course, we're going to need give the LAN access to the WAN (Internet), so lets do that
    nat = {
      enable = true;
      externalInterface = "WAN";
      internalInterfaces = [ "br0" ];
      internalIPs = [ "10.0.0.0/24" ];
      # You can customize this to your network, I like the 10.0.0.0 address range
      #because it allows you to refer to other devices like `ssh 10.1`.
    };
    # We also need to set up the WAN connection to get an IP
    interfaces = {
      "WAN" = {
        useDHCP = true;
        # tempAddresses = "disabled"; # Disable Temp Addresses for our ISP's sake.
      };
      # And on the Bridge, we're going to statically assign ourselves an IP
      "br0" = {
        ipv4.addresses = [
          {
            address = "10.0.0.1";
            prefixLength = 24;
          }
        ];
        useDHCP = false;
        macAddress = "02:07:a0:53:88:4d";
        # ^ This is the MAC address of the bridge. It's important to set this
        # so that the bridge has a predictable MAC address.
        # printf '02:%02x:%02x:%02x:%02x:%02x\n' $[$RANDOM%256] $[$RANDOM%256] $[$RANDOM%256] $[$RANDOM%256] $[$RANDOM%256]
      };
    };
  };
  services.resolved.enable = false;

  # services.dnsmasq = {
  #   enable = true;
  #   alwaysKeepRunning = true;
  #   settings = {
  #     # Network Interface
  #     interface = "br0";

  #     # Domain and host address
  #     domain = "example.com,10.0.0.1";
  #     address = "/example.com/10.0.0.1";

  #     # DHCP Configuration
  #     dhcp-range = [ "10.0.0.10,10.0.0.254,5m" ];

  #     # DHCP Options
  #     dhcp-option = [
  #       "3,10.0.0.1" # Default Gateway (Router)
  #       "121,10.0.0.0/24,10.0.0.1" # Classless Static Route
  #     ];

  #     # Static IP Assignments
  #     # Note: Use a list if you have multiple hosts
  #     # dhcp-host = [ "AA:BB:CC:DD:EE:FF,10.0.0.2" ];

  #     # DNS Server Settings
  #     listen-address = [
  #       "127.0.0.1"
  #       "10.0.0.1"
  #     ];
  #     expand-hosts = true;

  #     # Upstream DNS Servers
  #     server = [
  #       "192.168.1.1"
  #       # "1.1.1.1"
  #       # "8.8.8.8"
  #     ];
  #   };
  # };

  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config = {
        interfaces = [ "br0" ];
      };

      lease-database = {
        type = "memfile";
        persist = true;
        name = "/var/lib/kea/kea-leases4.csv";
      };

      # Replicating dnsmasq dhcp-range and options
      subnet4 = [
        {
          id = 1;
          subnet = "10.0.0.0/24";
          pools = [
            { pool = "10.0.0.10 - 10.0.0.254"; }
          ];

          # Replicating "5m" lease time
          valid-lifetime = 300;

          option-data = [
            {
              # dhcp-option 3 (Router)
              name = "routers";
              data = "10.0.0.1";
            }
            {
              # dhcp-option 6 (DNS) - Pointing to your local address 10.0.0.1
              name = "domain-name-servers";
              data = "10.0.0.1";
            }
            {
              # Replicating 'domain = example.com'
              name = "domain-name";
              data = "example.com";
            }
          ];

          # Replicating dhcp-host (Static Assignments)
          reservations = [
            # {
            #   hw-address = "AA:BB:CC:DD:EE:FF";
            #   ip-address = "10.0.0.2";
            #   hostname = "static-host";
            # }
          ];
        }
      ];
    };
  };

  boot.kernel.sysctl = {
    "net.core.rmem_max" = 4194304; # 4MB
    "net.core.wmem_max" = 4194304; # 4MB
  };
  services.unbound = {
    enable = true;
    settings = {
      server = {

        # Port for Unbound to listen for local clients (plain DNS)
        interface = [
          "127.0.0.1"
          "10.0.0.1"
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
          "10.0.0.0/24 allow" # Replace with your local subnet
          "0.0.0.0/0 refuse" # Block everyone else
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
        "1.1.1.1@853#cloudflare-dns.com"
        "1.0.0.1@853#cloudflare-dns.com"
      ];
    }
  ];
    };
  };

  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.interfaces."br0" = {
    allowedUDPPorts = [
      53
      67
    ];
    allowedTCPPorts = [
      53
      67
    ];
  };
}
