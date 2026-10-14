_: {
  flake.homeModules.homeOpencode = {
    pkgs,
    config,
    ...
  }: {
    sops.secrets."openrouter/ApiKey" = {};

    # Make `uvx` (used by the mcp-nixos MCP server below) reuse the
    # Nix-provided interpreter instead of downloading its own from
    # python-build-standalone on first run.
    home.packages = [pkgs.python3];
    home.sessionVariables.UV_PYTHON_PREFERENCE = "only-system";

    programs = {
      antigravity-cli.enable = true;
      codex = {
        enable = true;

        # Keep Codex useful for NixOS work without granting unrestricted
        # access to the host. Writes stay in the workspace and commands that
        # need broader access are approval-gated.
        settings = {
          approval_policy = "on-request";
          sandbox_mode = "workspace-write";
          web_search = "cached";

          mcp_servers.nixos = {
            command = "${pkgs.uv}/bin/uvx";
            args = ["mcp-nixos"];
          };
        };

        context = ''
          # nixos-config

          This is a flake-parts NixOS and Home Manager repository. Files under
          `modules/` are imported automatically. Follow the existing module
          structure and formatting.

          Before changing NixOS or Home Manager configuration, inspect the
          relevant host and shared module. Never read or expose files under
          `modules/hosts/*/secrets/` or `.env` files. Prefer build and dry-build
          checks before applying configuration; switching generations changes
          the system and requires explicit user approval.
        '';
      };
      claude-code = {
        enable = true;

        settings = {
          includeCoAuthoredBy = false;
          theme = "dark";
          effortLevel = "medium";

          permissions = {
            allow = [
              "Bash(git *)"
              "Bash(nix *)"
              "Bash(ls:*)"
              "Bash(cat:*)"
              "Bash(grep:*)"
              "Read(**/.env.example)"
              # Read-only nix workflow checks - safe to run without asking
              "Bash(home-manager build:*)"
              "Bash(nixos-rebuild build:*)"
              "Bash(nixos-rebuild dry-build:*)"
              "Bash(nixos-rebuild dry-activate:*)"
              "Bash(nix flake check:*)"
              "mcp__nixos__*"
              # sudo commands that have a matching NOPASSWD rule in
              # modules/hosts/themis/configuration.nix; any other sudo
              # command still falls through to the default prompt.
              "Bash(sudo journalctl:*)"
              "Bash(sudo systemctl status:*)"
              "Bash(sudo machinectl status:*)"
              "Bash(sudo machinectl list)"
            ];
            ask = [
              "Bash(git push:*)"
              "Bash(sops *)"
              # System-mutating - confirm before applying (ask/deny rules also
              # match with a sudo prefix stripped)
              "Bash(home-manager switch:*)"
              "Bash(nixos-rebuild switch:*)"
              "Bash(nixos-rebuild test:*)"
              "Bash(nixos-rebuild boot:*)"
              # No blanket "Bash(sudo *)" here: ask beats allow, so it would
              # override the sudo allow-list above. Unlisted sudo commands
              # still prompt, since nothing allows them.
              "Bash(curl:*)"
            ];
            deny = [
              "Read(**/.env)"
              "Read(**/.env.*)"
              "Read(modules/hosts/themis/secrets/**)"
              "Read(modules/hosts/xieshi/secrets/**)"
              "Bash(rm -rf *)"
              "Bash(wget:*)"
            ];
          };

          hooks = {
            PostToolUse = [
              {
                matcher = "Edit|MultiEdit|Write";
                hooks = [
                  {
                    type = "command";
                    command = ''file=$(${pkgs.jq}/bin/jq -r '.tool_input.file_path' <<< "$CLAUDE_TOOL_INPUT"); case "$file" in *.nix) ${pkgs.alejandra}/bin/alejandra -q "$file" ;; esac'';
                  }
                ];
              }
            ];
          };
        };

        lspServers = {
          nix = {
            command = "${pkgs.nixd}/bin/nixd";
            args = [];
            extensionToLanguage = {
              ".nix" = "nix";
            };
          };
        };

        mcpServers = {
          nixos = {
            type = "stdio";
            command = "${pkgs.uv}/bin/uvx";
            args = ["mcp-nixos"];
          };
        };

        context = ''
          # nixos-config

          Flake-parts based NixOS + home-manager monorepo. Every `.nix` file under
          `modules/` is auto-imported as a flake-parts module via `import-tree` (see
          `flake.nix`) - no manual wiring needed when adding a new module file, just
          drop it under `modules/` and export the relevant `flake.nixosModules.*` /
          `flake.homeModules.*` attribute.

          ## Layout
          - `modules/hosts/<host>/` - per-host NixOS config (`configuration.nix`,
            `hardware-configuration.nix`, `secrets/`). Hosts: `themis`, `xieshi`.
          - `modules/home/<user>@<host>/` - per-host home-manager entrypoint that
            imports the shared `homeModules.*` from `modules/*.nix`.
          - `modules/*.nix` - shared, composable modules (e.g. `opencode.nix` defines
            `homeModules.homeOpencode`), imported by one or more hosts.
          - `nixos.template.nix` / `home.template.nix` - copy these when adding a new
            host or home config.

          ## Secrets
          Managed with sops-nix. Each host has its own `secrets/config.yaml`
          referenced via `sops.defaultSopsFile` in that host's home/nixos module.
          Never read or print files under `modules/hosts/*/secrets/`.

          ## Applying changes
          - Check only: `home-manager build --flake .#<user>@<host>` or
            `nixos-rebuild build --flake .#<host>`.
          - Apply (asks for confirmation): `home-manager switch --flake .#<user>@<host>`
            or `sudo nixos-rebuild switch --flake .#<host>`.
          - Always build before switching when making non-trivial changes.
        '';
      };
    };
    programs.opencode = {
      enable = true;

      settings = {
        "$schema" = "https://opencode.ai/config.json";

        # Core settings
        lsp = true;
        model = "openrouter/free";
        small_model = "openrouter/free";

        # Security
        autoupdate = false;
        share = "disabled";
        snapshot = false;

        # Experimental policies - restrict to OpenRouter only
        experimental = {
          policies = [
            {
              effect = "deny";
              action = "provider.use";
              resource = "*";
            }
            {
              effect = "allow";
              action = "provider.use";
              resource = "openrouter";
            }
          ];
        };

        # Provider config
        provider.openrouter = {
          npm = "@ai-sdk/openai-compatible";
          name = "OpenRouter";
          options = {
            baseURL = "https://openrouter.ai/api/v1";
            apiKey = "{file:${config.sops.secrets."openrouter/ApiKey".path}}";
            # API key loaded from auth.json (via /connect) or OPENROUTER_API_KEY env var
          };
          models = {
            # Current free models (as of Sep 2026)
            "google/gemma-4-31b-it:free" = {};
            "google/gemma-4-26b-a4b-it:free" = {};
            "nvidia/nemotron-3-ultra-550b-a55b:free" = {};
            "nvidia/nemotron-3-super-120b-a12b:free" = {};
            "nvidia/nemotron-3.5-lightning:free" = {};
            "nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free" = {};
            "nvidia/nemotron-3.5-content-safety:free" = {};
            "minimax/minimax-m3:free" = {};
            "minimax/minimax-m2.7:free" = {};
            "z-ai/glm-5.2:free" = {};
            "cohere/north-mini-code:free" = {};
            "poolside/laguna-s-2.1:free" = {};
            "poolside/laguna-xs-2.1:free" = {};
            "inclusionai/ling-3.0-flash-fin:free" = {};
            "thinkingmachines/inkling:free" = {};
            "thinkingmachines/inkling-small:free" = {};
            "liquid/lfm-2.5-2.6b:free" = {};
            "dots-studio/dots-3-note-preview:free" = {};
            # Generic fallback
            "openrouter/free" = {};
          };
        };

        # Permissions - balanced (allow common ops, protect dangerous ones)
        permission = {
          "*" = "allow";
          # Block reading .env files by default (already default but explicit)
          read = {
            "*" = "allow";
            "*.env" = "deny";
            "*.env.*" = "deny";
            "*.env.example" = "allow";
            "modules/hosts/themis/secrets/**" = "deny";
            "modules/hosts/xieshi/secrets/**" = "deny";
          };
          edit = "allow";
          webfetch = "ask";
          websearch = "ask";
          # Prevent infinite loops of failed tool calls
          doom_loop = "ask";
          # Require approval for external directory access
          external_directory = "ask";
          bash = {
            "*" = "allow";
            "git *" = "allow";
            "npm *" = "allow";
            "ls *" = "allow";
            "cat *" = "allow";
            "grep *" = "allow";
            "rm -rf *" = "deny";
            "sudo *" = "deny";
            "curl *" = "deny";
            "wget *" = "deny";
            "chmod *" = "ask";
            "chown *" = "ask";
            "mkdir *" = "ask";
            "cp *" = "ask";
            "mv *" = "ask";
          };
        };

        # Performance - context management
        compaction = {
          auto = true;
          prune = true; # Remove old tool outputs to save tokens
          reserved = 15000; # Larger buffer for compaction
        };

        # Performance - file watching
        watcher = {
          ignore = [
            "node_modules/**"
            "dist/**"
            ".git/**"
            "target/**"
            "build/**"
            ".cache/**"
            "*.log"
            "*.tmp"
          ];
        };

        # Formatters - explicit config
        formatter = true;

        # LSP - explicit config
        lspConfig = {
          # Disable langs you don't use for performance
          # "python" = { disabled = true; };
        };
      };
    };
  };
}
