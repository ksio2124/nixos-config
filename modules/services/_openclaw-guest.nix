# Guest side of the OpenClaw microVM (host side: ./openclaw.nix). The
# leading underscore keeps import-tree from loading this as a flake module;
# it is only imported by microvm.vms.openclaw.
{
  inputs,
  lib,
  pkgs,
  ...
}: let
  hostV4 = "192.168.4.1";
  hostV6 = "fdcf:4b47:cf30:4::1";
  vmV4 = "192.168.4.2";
  vmV6 = "fdcf:4b47:cf30:4::2";
  mac = "02:00:00:00:04:02";

  # Build the gateway's EnvironmentFile from the credentials the host
  # passes in (see microvm.credentialFiles in ./openclaw.nix). Runs as root
  # ("+" prefix), so the secrets never go through the Nix store or the
  # world-readable /etc/openclaw/openclaw.json.
  # The unit imports them with ImportCredential= (below): system credentials
  # under /run/credentials/@system aren't visible inside the unit's mount
  # namespace, only its own $CREDENTIALS_DIRECTORY is.
  writeEnv = pkgs.writeShellScript "openclaw-write-env" ''
    set -euo pipefail
    key=$(cat "$CREDENTIALS_DIRECTORY/OPENROUTER_API_KEY")
    token=$(cat "$CREDENTIALS_DIRECTORY/GATEWAY_AUTH_TOKEN")
    [ -n "$key" ] && [ -n "$token" ] || { echo "openclaw credentials missing" >&2; exit 1; }
    install -d -m 0700 /run/openclaw-env
    umask 077
    printf 'OPENROUTER_API_KEY=%s\nOPENCLAW_GATEWAY_TOKEN=%s\n' "$key" "$token" > /run/openclaw-env/env
  '';
in {
  imports = [inputs.nix-openclaw.nixosModules.openclaw-gateway];

  system.stateVersion = "26.05";
  networking.hostName = "openclaw";

  microvm = {
    hypervisor = "qemu"; # cloud-hypervisor can't do credentialFiles
    vcpu = 6;
    mem = 8192;
    interfaces = [
      {
        type = "tap";
        id = "vm-openclaw";
        inherit mac;
      }
    ];
    # /var persists: OpenClaw state (/var/lib/openclaw), sshd host keys,
    # journal. Relative image path = /var/lib/microvms/openclaw/var.img on
    # the host's NVMe root.
    volumes = [
      {
        image = "var.img";
        mountPoint = "/var";
        size = 61440; # 60 GiB
      }
    ];
    shares = [
      {
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
        tag = "ro-store";
        proto = "virtiofs";
      }
    ];
  };

  # Static addresses on the point-to-point link to themis, plus a public
  # IPv6 address via SLAAC from the host's RA (delegated prefix).
  networking.useNetworkd = true;
  systemd.network.networks."10-uplink" = {
    matchConfig.MACAddress = mac;
    address = ["${vmV4}/24" "${vmV6}/64"];
    gateway = [hostV4];
    dns = [hostV6];
    networkConfig.IPv6AcceptRA = true;
  };
  networking.nameservers = [hostV6];

  # Inbound: themis may reach root SSH (debugging) and the gateway
  # (`ssh -L 18789:192.168.4.2:18789 jack@themis` tunnels); tailnet devices
  # may reach the gateway only. Headscale's ACL decides which devices.
  networking.nftables.enable = true;
  networking.firewall = {
    enable = true;
    extraInputRules = ''
      ip saddr ${hostV4} tcp dport { 22, 18789 } accept
      ip6 saddr ${hostV6} tcp dport { 22, 18789 } accept
    '';
    interfaces.tailscale0.allowedTCPPorts = [18789];
    # Tailscale's policy routing trips strict reverse-path checks.
    checkReversePath = "loose";
  };
  # https://openclaw.ts.ksio2124.com (443) -> gateway, so the phone URL
  # needs no port.
  networking.nftables.tables.openclaw-https = {
    family = "inet";
    content = ''
      chain prerouting {
        type nat hook prerouting priority dstnat; policy accept;
        iifname "tailscale0" tcp dport 443 redirect to :18789
      }
    '';
  };

  # Joins the self-hosted headscale on themis (reached through themis's
  # nginx; see the 443 rule in ./openclaw.nix). State lives on /var, so the
  # pre-auth key is only needed for the first login.
  services.tailscale = {
    enable = true;
    authKeyFile = "/run/credentials/tailscaled-autoconnect.service/TAILSCALE_AUTH_KEY";
    extraUpFlags = [
      "--login-server=https://headscale.ksio2124.com"
      "--hostname=openclaw"
      # No --advertise-tags: tag:openclaw comes from the pre-auth key, and
      # headscale 0.29 rejects a tagged-key node also requesting the tag.
      # Keep resolving through unbound on themis.
      "--accept-dns=false"
    ];
  };
  # System credentials aren't visible under /run/credentials/@system inside
  # units; import it into the unit that runs `tailscale up`.
  systemd.services.tailscaled-autoconnect.serviceConfig.ImportCredential = ["TAILSCALE_AUTH_KEY"];

  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
    # On the persistent /var volume so the host key survives reboots.
    hostKeys = [
      {
        path = "/var/lib/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILRTfkkswMAq8UBIVTaNg5mKe5FXamkRPN68Blhi3xGx jack@themis openclaw-vm debug"
  ];

  services.openclaw-gateway = {
    enable = true;
    # Explicit: the module's default picks pkgs.openclaw whenever nixpkgs
    # has it, which is nixpkgs' older build flagged insecure.
    package = inputs.nix-openclaw.packages.${pkgs.stdenv.hostPlatform.system}.openclaw-gateway;
    execStartPre = ["+${writeEnv}"];
    environmentFiles = ["-/run/openclaw-env/env"];
    # Tools the agent can use (tool sandbox is off: the VM is the sandbox).
    servicePath = with pkgs; [git curl jq ripgrep python3 gnugrep gnused findutils];

    config = {
      gateway = {
        mode = "local";
        # All IPv4 addresses (link to themis + tailscale0); the firewall
        # above decides who gets in. The gateway can't bind IPv6 ("custom"
        # requires an IPv4 host), so connections to the VM's tailnet IPv6
        # address are refused and browsers fall back to 100.64.0.3.
        bind = "lan";
        # Cert for openclaw.ts.ksio2124.com, obtained by themis (see
        # ./openclaw.nix) and imported as credentials below.
        tls = {
          enabled = true;
          certPath = "/run/credentials/openclaw-gateway.service/TLS_CERT";
          keyPath = "/run/credentials/openclaw-gateway.service/TLS_KEY";
        };
        auth = {
          mode = "token";
          token = "\${OPENCLAW_GATEWAY_TOKEN}";
          rateLimit = {
            maxAttempts = 10;
            windowMs = 60000;
            lockoutMs = 300000;
          };
        };
        controlUi.allowedOrigins = [
          # Phone/laptop on the tailnet (443 is redirected to the gateway).
          "https://openclaw.ts.ksio2124.com"
          "https://openclaw.ts.ksio2124.com:18789"
          # Local end of `ssh -L 18789:192.168.4.2:18789 jack@themis`
          # (the cert won't match localhost, so expect a warning).
          "https://localhost:18789"
          "https://127.0.0.1:18789"
        ];
      };
      # `openclaw security audit`: models <=300B shouldn't get tools that
      # pull in untrusted content while the tool sandbox is off.
      tools.byProvider = {
        "openrouter/nvidia/nemotron-3-super-120b-a12b:free".deny = ["group:web" "browser"];
        "openrouter/qwen/qwen3.8-27b:free".deny = ["group:web" "browser"];
      };
      # Only provider configured.
      models.providers.openrouter = {
        baseUrl = "https://openrouter.ai/api/v1";
        apiKey = "\${OPENROUTER_API_KEY}";
        # Free models whose OpenRouter endpoints support tool use (the agent
        # needs it). List them with:
        #   curl -s https://openrouter.ai/api/v1/models | jq -r '.data[]
        #     | select(.id|endswith(":free"))
        #     | select(.supported_parameters|index("tools")) | .id'
        models = [
          {
            id = "nvidia/nemotron-3-ultra-550b-a55b:free";
            name = "Nemotron 3 Ultra (free)";
            api = "openai-completions";
          }
          {
            id = "nvidia/nemotron-3-super-120b-a12b:free";
            name = "Nemotron 3 Super (free)";
            api = "openai-completions";
          }
          {
            id = "qwen/qwen3.8-27b:free";
            name = "Qwen3.8 27B (free)";
            api = "openai-completions";
          }
        ];
      };
      agents.defaults = {
        model = {
          primary = "openrouter/nvidia/nemotron-3-ultra-550b-a55b:free";
          fallbacks = [
            "openrouter/nvidia/nemotron-3-super-120b-a12b:free"
            "openrouter/qwen/qwen3.8-27b:free"
          ];
        };
        sandbox.mode = "off";
      };
      update.checkOnStart = false;
    };
  };

  # The module installs it 0644; it holds only ${VAR} placeholders, but the
  # audit (rightly) wants it private to the gateway user.
  environment.etc."openclaw/openclaw.json" = {
    mode = lib.mkForce "0400";
    user = "openclaw";
  };

  # Belt and braces inside the VM: the agent runs as the unprivileged
  # openclaw user and may only write its own state dir.
  systemd.services.openclaw-gateway.serviceConfig = {
    ImportCredential = ["OPENROUTER_API_KEY" "GATEWAY_AUTH_TOKEN" "TLS_CERT" "TLS_KEY"];
    NoNewPrivileges = true;
    ProtectSystem = "strict";
    ReadWritePaths = ["/var/lib/openclaw"];
    ProtectHome = true;
    PrivateTmp = true;
    PrivateDevices = true;
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectControlGroups = true;
    # No RestrictSUIDSGID: its seccomp filter makes openat2() return ENOSYS,
    # and the gateway's state lock uses openat2 with no openat fallback.
    LockPersonality = true;
  };
}
