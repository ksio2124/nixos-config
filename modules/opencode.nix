_: {
  flake.homeModules.homeOpencode =
    {
      pkgs,
      config,
      ...
    }:
    {
      sops.secrets."openrouter/ApiKey" = { };
      imports = [ ];
      programs.opencode = {
        enable = true;

        settings = {
          "$schema" = "https://opencode.ai/config.json";

          # Core settings
          lsp = true;
          model = "openrouter/qwen/qwen-2.5-coder-32b-instruct:free";
          small_model = "openrouter/google/gemma-2-9b-it:free";

          # Security
          autoupdate = false;
          share = "disabled";
          snapshot = false;

          # Experimental policies - restrict to OpenRouter, NVIDIA, Groq only
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
              {
                effect = "allow";
                action = "provider.use";
                resource = "nvidia";
              }
              {
                effect = "allow";
                action = "provider.use";
                resource = "groq";
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
              # Best free coding models (as of Aug 2026)
              "qwen/qwen-2.5-coder-32b-instruct:free" = { };
              "z-ai/glm-4.5v:free" = { };
              "meta-llama/llama-3.1-8b-instruct:free" = { };
              "google/gemma-2-9b-it:free" = { };
              "microsoft/phi-3.5-mini-instruct:free" = { };
              "nvidia/nemotron-3-ultra:free" = { };
              "deepseek/deepseek-chat-v3:free" = { };
              "inclusionai/ling-3.0-flash-fin:free" = { };
              # Keep existing as fallbacks
              "z-ai/glm-5.2:free" = { };
              "nvidia/nemotron-3-super-120b-a12b:free" = { };
              "minimax/minimax-m3:free" = { };
              "cohere/north-mini-code:free" = { };
              "poolside/laguna-s-2.1:free" = { };
              # Generic fallback
              "openrouter/free" = { };
            };
          };

          # NVIDIA - Free Nemotron models (excellent for coding)
          provider.nvidia = {
            npm = "@ai-sdk/openai-compatible";
            name = "NVIDIA";
            options = {
              baseURL = "https://integrate.api.nvidia.com/v1";
              # API key from build.nvidia.com
            };
            models = {
              "nemotron-3-ultra" = { };
              "nemotron-3-super" = { };
            };
          };

          # Groq - Ultra-fast inference (free tier)
          provider.groq = {
            npm = "@ai-sdk/groq";
            name = "Groq";
            options = {
              # API key from console.groq.com
            };
            models = {
              "llama-3.1-70b-versatile" = { };
              "llama-3.1-8b-instant" = { };
              "mixtral-8x7b-32768" = { };
              "gemma2-9b-it" = { };
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
            };
            edit = "allow";
            webfetch = "ask";
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
              "chmod *" = "allow";
              "chown *" = "allow";
              "mkdir *" = "allow";
              "cp *" = "allow";
              "mv *" = "allow";
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
