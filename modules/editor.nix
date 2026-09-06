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
              trouble.enable = true;
              lspSignature.enable = true;
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
            # Yank over SSH has no local clipboard to shell out to - OSC52
            # makes nvim emit the copied text as an escape sequence instead,
            # which the local terminal (e.g. WezTerm) picks up and writes to
            # its own system clipboard.
            clipboard = {
              enable = true;
              registers = "unnamedplus";
            };
            luaConfigPost = ''
              vim.g.clipboard = require("vim.ui.clipboard.osc52")
            '';
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
              rust = {
                enable = true;
                extensions.crates-nvim.enable = true;
              };
              markdown = {
                enable = true;
              };
              toml = {
                enable = true;
              };
              python.enable = true;
              lua.enable = true;
              yaml.enable = true;
            };
          };
        };
      };
    };
  };
}
