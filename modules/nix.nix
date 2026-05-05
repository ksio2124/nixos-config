_: {
  flake.nixosModules.nix = {pkgs, ...}: {
    programs = {
      direnv = {
        enable = true;
        silent = false;
        loadInNixShell = true;
        direnvrcExtra = "";
        nix-direnv = {
          enable = true;
        };
      };
      zsh.enable = true;
      firefox.enable = true;
      nix-ld.enable = true;
    };
    fonts.packages = with pkgs; [
      nerd-fonts.fira-code
      nerd-fonts.droid-sans-mono
      inter
      montserrat
      lato
    ];
    environment.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };
    nix.settings = {
      experimental-features = ["nix-command" "flakes"];
      trusted-users = ["root" "@wheel"];
      download-buffer-size = 524288000;
    };
    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [
      neovim
    ];
    users.users.jack = {
      isNormalUser = true;
      description = "jack";
      shell = pkgs.zsh;
      extraGroups = [
        "networkmanager"
        "wheel"
        "video"
        "render"
        "input"
        "uinput"
      ];
      packages = with pkgs; [
        home-manager
      ];
    };
  };
}
