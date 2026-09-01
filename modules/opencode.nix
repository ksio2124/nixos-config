_: {
  flake.homeModules.homeOpencode =
    {
      pkgs,
      config,
      ...
    }:
    {
      sops.secrets."openrouter/ApiKey" = { };
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
              "google/gemma-4-31b-it:free" = { };
              "google/gemma-4-26b-a4b-it:free" = { };
              "nvidia/nemotron-3-ultra-550b-a55b:free" = { };
              "nvidia/nemotron-3-super-120b-a12b:free" = { };
              "nvidia/nemotron-3.5-lightning:free" = { };
              "nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free" = { };
              "nvidia/nemotron-3.5-content-safety:free" = { };
              "minimax/minimax-m3:free" = { };
              "minimax/minimax-m2.7:free" = { };
              "z-ai/glm-5.2:free" = { };
              "cohere/north-mini-code:free" = { };
              "poolside/laguna-s-2.1:free" = { };
              "poolside/laguna-xs-2.1:free" = { };
              "inclusionai/ling-3.0-flash-fin:free" = { };
              "thinkingmachines/inkling:free" = { };
              "thinkingmachines/inkling-small:free" = { };
              "liquid/lfm-2.5-2.6b:free" = { };
              "dots-studio/dots-3-note-preview:free" = { };
              # Generic fallback
              "openrouter/free" = { };
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
