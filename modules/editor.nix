{inputs, ...}: {
  flake.homeModules.homeEditor = {pkgs, ...}: {
    # pkgs
    imports = [
      inputs.nvf.homeManagerModules.default
      # import homeModules here
    ];
    programs = {
      neovim = {
        withPython3 = false;
        withRuby = false;
        enable = true;
        defaultEditor = true;
      };

      nvf = {
        enable = true;
        settings = {
          vim = {
            extraPlugins = with pkgs.vimPlugins; {
              vim-nftables = {
                package = vim-nftables;
                # setup = "require('vim-nftables').setup {}";
              };
            };
            theme = {
              enable = true;
              name = "tokyonight";
              style = "moon";
            };
            lsp = {
              lightbulb.enable = true;
              enable = true;
              formatOnSave = true;
              # trouble.enable = true;
            };
            diagnostics = {
              enable = true;
              config.virtual_lines = true;
              # config.float.source = "always";
            };
            telescope.enable = true;

            git.enable = true;
            treesitter = {
              fold = true;
              enable = true;
            };
            options = {
              foldlevel = 99; # Start with all folds open
              foldlevelstart = 99; # Ensure new buffers start unfolded
              # Ensure folds open on common actions
              foldopen = "block,hor,mark,percent,quickfix,search,tag,undo";
            };
            autocomplete.nvim-cmp.enable = true;
            filetree.nvimTree.enable = true;
            tabline.nvimBufferline.enable = true;
            autopairs.nvim-autopairs.enable = true;
            statusline.lualine.enable = true;
            languages = {
              enableExtraDiagnostics = true;
              enableFormat = true;
              enableTreesitter = true;
              nix = {
                enable = true;
                lsp.servers = ["nixd"];
              };
              lua.enable = true;
              yaml.enable = true;
            };
          };
        };
      };
    };
  };
}
