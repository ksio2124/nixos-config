{
  flake.nixosModules.hostThemis = {lib, ...}: let
    sunshineTCP = [47984 47989 48010 48011];
    sunshineUDP = [47998 47999 48000 48002 48010];
    mailPorts = [25 465 587 993 995];
  in {
    networking.nftables.enable = true;
    networking.firewall = {
      enable = true;

      # This box is the router: never open a port on every interface (that
      # includes wan). Modules with openFirewall = true (openssh, avahi) would
      # otherwise add 22/5353 globally. Open ports per interface below instead.
      allowedTCPPorts = lib.mkForce [];
      allowedUDPPorts = lib.mkForce [];
      allowedTCPPortRanges = lib.mkForce [];
      allowedUDPPortRanges = lib.mkForce [];

      interfaces = {
        wan = {
          allowedTCPPorts = [
            80
            443
            8883 # mosquitto mqtts IPv4 relay (stream proxy to container)
          ];
          allowedUDPPorts = [41641]; # tailscale
        };
        br0 = {
          allowedTCPPorts = [22 53 80 443] ++ sunshineTCP;
          allowedUDPPorts = [53 67 68 5353] ++ sunshineUDP;
        };
        tailscale0 = {
          allowedTCPPorts = [22] ++ sunshineTCP;
          allowedUDPPorts = sunshineUDP;
        };
        br-isolated.allowedUDPPorts = [53 67 68];
        ve-mailserver.allowedUDPPorts = [53 67 68];
      };

      extraInputRules = ''
        iifname "br0" pkttype broadcast accept
      '';

      # Strict everywhere; loose on tailscale0, whose policy routing
      # (table 52, fwmarks) can trip strict checks for exit-node traffic.
      checkReversePath = "strict";
      extraReversePathFilterRules = ''
        iifname "tailscale0" fib saddr . mark oif exists accept
      '';
      logReversePathDrops = true;
      logRefusedConnections = false; # wan gets scanned constantly

      filterForward = true;
      # forward-allow already has "ct status dnat accept" (covers the mail
      # port forward below); networking.nat adds "internal ifaces -> wan".
      extraForwardRules = ''
        oifname "br-isolated" tcp dport { 80, 443, 8883 } accept comment "container web + mqtts (IPv6 direct, IPv4 via host proxy)"
        ip daddr 10.0.0.14 tcp dport { ${lib.concatMapStringsSep ", " toString mailPorts} } accept comment "mailserver from LAN (split-horizon DNS)"
        iifname "br-isolated" oifname "ve-mailserver" ip6 daddr fdcf:4b47:cf30:1::2 tcp dport { 465, 993 } accept comment "Nextcloud to mailserver"
      '';
    };

    networking.nat = {
      enable = true;
      externalInterface = "wan";
      internalInterfaces = ["br0" "br-isolated" "ve-mailserver" "tailscale0"];
    };

    # Mail port forward. Not networking.nat.forwardPorts: that always adds a
    # "port forward loopback snat" rule, which would masquerade LAN clients
    # reaching 10.0.0.14 directly (split-horizon DNS) so the mailserver would
    # see every LAN client as 10.0.0.13.
    networking.nftables.tables.mail-forward = {
      family = "ip";
      content = ''
        chain prerouting {
          type nat hook prerouting priority dstnat; policy accept;
          iifname "wan" tcp dport { ${lib.concatMapStringsSep ", " toString mailPorts} } dnat to 10.0.0.14
          # LAN clients may use public DNS or a cached WAN address instead
          # of the split-horizon answer. Match only this router's addresses
          # so connections to external mail providers remain untouched.
          # The container routes replies through us, so no SNAT is needed.
          iifname "br0" fib daddr type local tcp dport { ${lib.concatMapStringsSep ", " toString mailPorts} } dnat to 10.0.0.14
          iifname "br-isolated" fib daddr type local tcp dport { ${lib.concatMapStringsSep ", " toString mailPorts} } dnat to 10.0.0.14
        }
      '';
    };

    # Clamp TCP MSS to the route MTU on forwarded SYNs (wan runs a 9000 MTU,
    # the LAN bridges 1500).
    networking.nftables.tables.mss-clamp = {
      family = "inet";
      content = ''
        chain forward {
          type filter hook forward priority mangle; policy accept;
          tcp flags syn tcp option maxseg size set rt mtu
        }
      '';
    };
  };
}
