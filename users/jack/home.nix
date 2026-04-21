{
  pkgs,
  nur,
  ...
}: {
  # pkgs
  nixpkgs.overlays = [nur.overlays.default];
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
    # pkgs.heroic
    # unstable.stremio
    pkgs.calibre
    pkgs.pdfarranger
    pkgs.unciv
    pkgs.logseq
    pkgs.devenv
    # unstable._010editor
    # unstable.biome
    pkgs.cudaPackages.cuda_nvcc
    pkgs.endless-sky
    pkgs.freecad
    # pkgs.torrential
    pkgs.tesseract
    pkgs.imagemagickBig
    pkgs.poppler-utils
    # unstable.python313Packages.paddlepaddle
    # pkgs.python313Packages.paddleocr
    # unstable.python313Packages.paddlex
    # paddlex
    pkgs.ccache
    pkgs.google-chrome
    pkgs.youtube-tui
    pkgs.chawan
    pkgs.xournalpp
    # pkgs.phoronix-test-suite
    pkgs.geekbench
    # pkgs.intel-gpu-tools
    pkgs.nvtopPackages.full
    pkgs.lzip
    pkgs.retroarch-free
    pkgs.cachix
    pkgs.sbctl
    pkgs.btop
    pkgs.ndisc6
    pkgs.mtr
    pkgs.iperf3
    pkgs.age
    pkgs.sops
    pkgs.ssh-to-age
    pkgs.ethtool
    pkgs.pciutils
    pkgs.lsof
    pkgs.wireguard-tools
    # pkgs.gnomeExtensions.tophat
    pkgs.gnomeExtensions.caffeine
    pkgs.gnomeExtensions.astra-monitor
    pkgs.gnomeExtensions.bluetooth-battery-meter
    pkgs.gnomeExtensions.gsconnect
    # pkgs.termshark
    pkgs.wireshark
    pkgs.remmina
    pkgs.qjackctl
    pkgs.carla
    # pkgs.ciscoPacketTracer8
    #pkgs.cisco-packet-tracer_9
    # pkgs.stremio
    pkgs.firejail
    pkgs.unigine-superposition
    pkgs.gns3-gui
    pkgs.gns3-server
    pkgs.freetube
    pkgs.kiwix
    pkgs.opencode
    pkgs.statix
    pkgs.deadnix
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
          # Put UUIDs of extensions that you want to enable here.
          # If the extension you want to enable is packaged in nixpkgs,
          # you can easily get its UUID by accessing its extensionUuid
          # field (look at the following example).
          # pkgs.gnomeExtensions.blurt.extensionUuid
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
    neovim = {
      withPython3 = false;
      withRuby = false;
      enable = true;
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

  programs.nvf = {
    enable = true;
    settings = {
      vim.extraPlugins = with pkgs.vimPlugins; {
        vim-nftables = {
          package = vim-nftables;
          # setup = "require('vim-nftables').setup {}";
        };
      };
      vim.theme = {
        enable = true;
        name = "tokyonight";
        style = "moon";
      };
      vim.lsp.enable = true;
      vim.lsp.formatOnSave = true;
      vim.diagnostics.enable = true;
      vim.telescope.enable = true;
      vim.diagnostics.config = {
        float.source = "always";
      };
      vim.git.enable = true;
      vim.autopairs.nvim-autopairs.enable = true;
      vim.statusline.lualine.enable = true;
      vim.treesitter.enable = true;
      vim.autocomplete.nvim-cmp.enable = true;
      vim.filetree.nvimTree.enable = true;
      vim.tabline.nvimBufferline.enable = true;
      vim.languages = {
        enableExtraDiagnostics = true;
        enableFormat = true;
        enableTreesitter = true;
        nix = {
          enable = true;
          lsp.servers = ["nixd"];
        };
        lua.enable = true;
      };
    };
  };

  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "25.05";
}
# Install firefox.

