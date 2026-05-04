_: {
  flake.nixosModules.nix = {pkgs, ...}: {
    programs.direnv = {
      enable = true;
      silent = false;
      loadInNixShell = true;
      direnvrcExtra = "";
      nix-direnv = {
        enable = true;
      };
    };

    nix.settings.experimental-features = ["nix-command" "flakes"];
    nix.settings.trusted-users = ["root" "@wheel"];
    programs.nix-ld.enable = true;
    nixpkgs.config.allowUnfree = true;

    nix.settings.download-buffer-size = 524288000;
    environment.systemPackages = with pkgs; [
      # Nix tooling
      nil
      nixd
      statix
      alejandra
      manix
      nix-inspect
    ];
  };
}
