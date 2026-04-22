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
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    self,
    nixpkgs,
    home-manager,
    nur,
    nvf,
    lanzaboote,
    sops-nix,
    ...
  }: {
    nixosConfigurations = {
      xieshi = let
        system = "x86_64-linux";
        specialArgs = {inherit system;};
      in
        nixpkgs.lib.nixosSystem {
          modules = [
            lanzaboote.nixosModules.lanzaboote
            nur.modules.nixos.default
            ./hosts/xieshi/configuration.nix
            sops-nix.nixosModules.sops
          ];
        };
      themis = let
        system = "x86_64-linux";
        specialArgs = {inherit system;};
      in
        nixpkgs.lib.nixosSystem {
          modules = [
            lanzaboote.nixosModules.lanzaboote
            nur.modules.nixos.default
            sops-nix.nixosModules.sops
            ./hosts/themis/configuration.nix
          ];
        };
    };
    homeConfigurations."jack" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      extraSpecialArgs = {inherit nur;};
      modules = [
        nvf.homeManagerModules.default
        ./users/jack/home.nix
      ];
    };
  };
}
