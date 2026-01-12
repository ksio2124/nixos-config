{ pkgs, nur, ... }:
{
  # pkgs
  nixpkgs.overlays = [ nur.overlays.default ];
  home.username = "jack";
  home.homeDirectory = "/home/jack";
  home.packages = [
    pkgs.nixd
    pkgs.alejandra
    pkgs.lshw
    pkgs.nixfmt-rfc-style
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
    pkgs.youtube-music
    pkgs.spotify
    pkgs.libva-utils
    pkgs.godot_4
    pkgs.gpu-screen-recorder-gtk
    pkgs.mangohud
    pkgs.protonup-ng
    pkgs.lutris
    pkgs.bottles
    pkgs.heroic
    # unstable.stremio
    pkgs.calibre
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
  ];
  dconf = {
    enable = true;
    settings = {
      "org/gnome/shell" = {
        disable-user-extensions = false; # enables user extensions
        enabled-extensions = [
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
    mpv.enable = true;
    neovim.enable = true;
  };

  programs.zellij = {
    enable = true;
    # enableZshIntegration = true;
  };

  programs.mcfly = {
    enable = true;
    enableZshIntegration = true;
    fzf.enable = true;
  };

  nixpkgs.config.allowUnfree = true;
  programs.git = {
    enable = true;
    userName = "jack";
    userEmail = "ksio2124@protonmail.ch";
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
  };
  programs.fzf = {
    enable = true;
    enableZshIntegration = true; # Since you're using ZSH
  };
  programs.vscode = {
    enable = true;
    extensions = [
      pkgs.vscode-extensions.jnoortheen.nix-ide
      pkgs.vscode-extensions.github.copilot
      pkgs.vscode-extensions.github.copilot-chat
      pkgs.vscode-extensions.esbenp.prettier-vscode
      pkgs.vscode-extensions.dbaeumer.vscode-eslint
      pkgs.vscode-extensions.biomejs.biome
      pkgs.vscode-extensions.bradlc.vscode-tailwindcss
      pkgs.vscode-extensions.james-yu.latex-workshop
      pkgs.vscode-extensions.eamodio.gitlens
      pkgs.vscode-extensions.continue.continue
      pkgs.vscode-extensions.ritwickdey.liveserver
      pkgs.vscode-extensions.ms-vscode-remote.remote-ssh
      # pkgs.vscode-extensions.ms-vscode-remote.vscode-remote-extensionpack
    ];
  };
  programs.firefox = {
    enable = true;
    profiles.default = {
      extensions = with pkgs.nur.repos.rycee.firefox-addons; [
        ublock-origin
        bitwarden
        react-devtools
      ];
    };
  };

  programs.alacritty = {
    enable = true;
    settings = {
      font.normal.family = "FiraCode Nerd Font";
      window.opacity = 0.95;
    };
  };

  programs.home-manager = {
    enable = true;
  };

  programs.nvf = {
    enable = true;
    settings = {
      vim.languages = {
        nix.enable = true;
        nix.extraDiagnostics.enable = true;
        nix.format.enable = true;
        nix.lsp.enable = true;
        nix.treesitter.enable = true;
      };
    };
  };

  services.ssh-agent = {
    enable = true;
    enableZshIntegration = true;
  };
  # The state version is required and should stay at the version you
  # originally installed.
  home.stateVersion = "25.05";
}
# Install firefox.
