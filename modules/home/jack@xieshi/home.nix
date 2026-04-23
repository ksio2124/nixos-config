{
  inputs,
  self,
  ...
}: {
  flake.homeConfigurations."jack@xieshi" = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
    modules = [
      self.homeModules."homeJack@xieshi"
    ];
  };

  flake.homeModules."homeJack@xieshi" = {pkgs, ...}: {
    # pkgs
    imports = [
      self.homeModules.homeEditor
    ];
    nixpkgs.overlays = [inputs.nur.overlays.default];
    nixpkgs.config.permittedInsecurePackages = [
      "ciscoPacketTracer8-8.2.2"
      "qtwebengine-5.15.19"
    ];

    home.username = "jack";
    home.homeDirectory = "/home/jack";
    home.packages = [
      pkgs.nixd
      pkgs.alejandra
      pkgs.lshw
      pkgs.nixfmt
      pkgs.discord
      pkgs.zoom-us
      pkgs.vlc
      pkgs.lmstudio
      pkgs.moonlight-qt
      pkgs.libreoffice
      pkgs.gimp
      pkgs.figma-linux
      pkgs.signal-desktop
      pkgs.xdotool
      pkgs.jq
      pkgs.libva-utils
      pkgs.godot_4
      pkgs.gpu-screen-recorder-gtk
      pkgs.mangohud
      pkgs.protonup-ng
      pkgs.lutris
      pkgs.bottles
      pkgs.calibre
      pkgs.unciv
      pkgs.devenv
      pkgs.endless-sky
      pkgs.freecad
      pkgs.tesseract
      pkgs.imagemagickBig
      pkgs.poppler-utils
      pkgs.google-chrome
      pkgs.xournalpp
      pkgs.nvtopPackages.full
      pkgs.lzip
      pkgs.retroarch-free
      pkgs.sbctl
      pkgs.btop
      pkgs.ndisc6
      pkgs.mtr
      pkgs.iperf3
      pkgs.sops
      pkgs.age
      pkgs.ssh-to-age
      pkgs.ethtool
      pkgs.pciutils
      pkgs.lsof
      pkgs.wireguard-tools
      pkgs.gnomeExtensions.caffeine
      pkgs.gnomeExtensions.astra-monitor
      pkgs.gnomeExtensions.bluetooth-battery-meter
      pkgs.gnomeExtensions.gsconnect
      pkgs.wireshark
      pkgs.qjackctl
      pkgs.carla
      pkgs.cisco-packet-tracer_9
      pkgs.unigine-superposition
      pkgs.freetube
      pkgs.kiwix
      pkgs.opencode
      pkgs.statix
      pkgs.deadnix
      pkgs.wl-clipboard
      pkgs.anki
      pkgs.wesnoth
      (pkgs.ffmpeg-full.override
        {withUnfree = true;})
    ];
    dconf = {
      enable = true;
      settings = {
        "org/gnome/shell" = {
          disable-user-extensions = false; # enables user extensions
          enabled-extensions = [
            pkgs.gnomeExtensions.astra-monitor.extensionUuid
            pkgs.gnomeExtensions.caffeine.extensionUuid
            pkgs.gnomeExtensions.bluetooth-battery-meter.extensionUuid
            pkgs.gnomeExtensions.gsconnect.extensionUuid
          ];
        };
      };
    };
    programs = {
      chromium.enable = true;
      obs-studio.enable = true;
      yt-dlp.enable = true;
      mpv = {
        enable = true;
        # config = {
        #   hwdec = "vaapi";
        # };
      };
      ripgrep.enable = true;
      fd.enable = true;
    };

    programs.mcfly = {
      enable = true;
      enableZshIntegration = true;
      fzf.enable = true;
    };

    nixpkgs.config.allowUnfree = true;
    programs.git = {
      enable = true;
      settings.user = {
        name = "jack";
        email = "ksio2124@protonmail.ch";
      };
    };
    programs.texlive = {
      enable = true;
      extraPackages = tpkgs: {
        inherit (tpkgs) scheme-full;
      };
    };
    programs.direnv = {
      enable = true;
      enableZshIntegration = true; # Since you're using ZSH
      nix-direnv = {
        enable = true;
      };
    };
    programs.navi = {
      enable = true;
      enableZshIntegration = true; # Since you're using ZSH
    };
    programs.starship = {
      enable = true;
      enableZshIntegration = true; # Since you're using zsh
      settings = {
        # Example settings
        nix_shell = {
          symbol = "❄️ ";
          format = "via [$symbol$state( \($name\))]($style) ";
        };
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[✗](bold red)";
        };
      };
    };

    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      historySubstringSearch = {
        enable = true;
        searchDownKey = ["$key[Down]"];
        searchUpKey = ["$key[Up]"];
      };
      history = {
        append = true;
        findNoDups = true;
        ignoreAllDups = true;
        saveNoDups = true;
      };
      initContent = ''
        # Enable the menu select widget
        zstyle ':completion:*' menu no
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'

        # Optional: Better visuals (highlight current selection)
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}

        zstyle 'completion:*' matcher-list 'm:{a-z}={A-Za-z}'
      '';
      plugins = [
        {
          name = "fzf-tab";
          src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
        }
      ];
    };
    programs.fzf = {
      enable = true;
      enableZshIntegration = true; # Since you're using ZSH
    };
    programs.firefox = {
      enable = true;
      profiles.default = {
        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          bitwarden
          react-devtools
        ];
      };
    };

    programs.wezterm = {
      enable = true;
      enableZshIntegration = true;
      extraConfig = builtins.readFile ./wezterm.lua;
    };

    programs.home-manager = {
      enable = true;
    };

    services.ssh-agent = {
      enable = true;
    };

    # The state version is required and should stay at the version you
    # originally installed.
    home.stateVersion = "25.05";
  };
}
