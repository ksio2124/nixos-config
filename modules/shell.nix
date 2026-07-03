_: {
  flake.homeModules.homeShell = {pkgs, ...}: {
    # pkgs
    imports = [
      # import homeModules here
    ];
    programs = {
      zsh = {
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
        loginExtra = "fastfetch";
        plugins = [
          {
            name = "fzf-tab";
            src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
          }
        ];
      };
      fzf = {
        enable = true;
        enableZshIntegration = true; # Since you're using ZSH
      };
      mcfly = {
        enable = true;
        enableZshIntegration = true;
        fzf.enable = true;
      };
      direnv = {
        enable = true;
        enableZshIntegration = true; # Since you're using ZSH
        nix-direnv = {
          enable = true;
        };
      };
      starship = {
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
      home-manager.enable = true;
      git = {
        enable = true;
        settings.user = {
          name = "jack";
          email = "ksio2124@protonmail.ch";
        };
      };
      ripgrep.enable = true;
      fd.enable = true;
    };

    services.ssh-agent.enable = true;

    nixpkgs.config.allowUnfree = true;
  };
}
