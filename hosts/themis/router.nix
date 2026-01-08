{
  config,
  pkgs,
  lib,
  ...
}:

{
  networking.usePredictableInterfaceNames = false;
  services = {
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
  
  services.dnsmasq = {
    enable = true;
    alwaysKeepRunning = true;
    settings = {
      # Network Interface
      interface = "br0";

      # Domain and host address
      domain = "example.com,10.0.0.1";
      address = "/example.com/10.0.0.1";

      # DHCP Configuration
      dhcp-range = [ "10.0.0.10,10.0.0.254,5m" ];

      # DHCP Options
      dhcp-option = [
        "3,10.0.0.1" # Default Gateway (Router)
        "121,10.0.0.0/24,10.0.0.1" # Classless Static Route
      ];

      # Static IP Assignments
      # Note: Use a list if you have multiple hosts
      # dhcp-host = [ "AA:BB:CC:DD:EE:FF,10.0.0.2" ];

      # DNS Server Settings
      listen-address = [
        "127.0.0.1"
        "10.0.0.1"
      ];
      expand-hosts = true;

      # Upstream DNS Servers
      server = [
        "1.1.1.1"
        "8.8.8.8"
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
