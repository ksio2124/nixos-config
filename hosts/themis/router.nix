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
        tempAddresses = "disabled"; # Disable Temp Addresses for our ISP's sake.
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

  services.dnsmasq = {
    enable = true;
    alwaysKeepRunning = true;
    extraConfig = ''
      interface=br0
      domain=example.com,10.0.0.1
      # ^ Domain and Address of the host.
      dhcp-range=10.0.0.10,10.0.0.254,5m
      # ^ All IP addresses between that range will be handed out with a 5 minute lease time.
      # It also reserves the first 10 addresses for static IP's.
      dhcp-option=3,10.0.0.1
      # ^ This is the primary DNS. DNSMasq will also be the DNS server, 
      # since it can cache. You can point this wherever you wish.
      dhcp-option=121,10.0.0.0/24.10.0.0.1
      # ^ This is a classless static route. I'm not 100% sure what it does, 
      # but things seem to work better with it. Apparently Windows ignores this.

      # From here you can set up static IP's for your devices, if you want.
      dhcp-host:AA:BB:CC:DD:EE:FF,10.0.0.2
      # Repeat as needed.

      # DNS
      listen-address=1,127.0.0.1,10.0.0.1
      # It listens on both the local and the bridge interface.
      expand-hosts
      # This will allow you to refer to devices by their hostname.
      server=1.1.1.1  
      # ^ This is Cloudflare's DNS server. You can use whatever you want.
      server=8.8.8.8
      # ^ We're using Google's DNS as backup.
      address=/example.com/10.0.0.1
      # ^ This is a static DNS entry. It will resolve example.com to 10.0.0.1, or in other words, the router.
    '';
  };
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
