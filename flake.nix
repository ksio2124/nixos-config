{
  description = "flake for all systems";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nvf.url = "github:notashelf/nvf";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.0.0";

      # Optional but recommended to limit the size of your system closure.
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # microvm = {
    #   url = "github:microvm-nix/microvm.nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    vscode-server.url = "github:nix-community/nixos-vscode-server";

    # Get the hash of the latest master
    # nix shell nixpkgs#nurl --command nurl https://github.com/StevenBlack/hosts master
    # > fetchFromGitHub {
    #   owner = "StevenBlack";
    #   repo = "hosts";
    #   rev = "master";
    #   hash = "sha256-fPMGNj1dXrbxJDxiC8U41NLz1vL5m3Ayw8uC1HJm4sU="; # <-- this
    # }

    # # Update it in flake.nix
    blocklist.url = "github:mirosval/unbound-blocklist";
  };
  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nur,
      nvf,
      lanzaboote,
      vscode-server,
      blocklist,
      sops-nix,
      ...
    }:
    {
      nixosConfigurations = {
        xieshi =
          let
            system = "x86_64-linux";
            specialArgs = { inherit system; };
          in
          nixpkgs.lib.nixosSystem {
            modules = [
              nur.modules.nixos.default
              ./hosts/xieshi/configuration.nix
            ];
          };
        themis =
          let
            system = "x86_64-linux";
            specialArgs = { inherit system; };
          in
          nixpkgs.lib.nixosSystem {
            modules = [
              lanzaboote.nixosModules.lanzaboote
              nur.modules.nixos.default
              vscode-server.nixosModules.default
              sops-nix.nixosModules.sops
              # microvm.nixosModules.microvm
              # blocklist.nixosModules.default
              ./hosts/themis/configuration.nix
            ];
          };
      };
      homeConfigurations."jack" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = { inherit nur; };
        modules = [
          nvf.homeManagerModules.default
          ./users/jack/home.nix
        ];
      };
    };
}
