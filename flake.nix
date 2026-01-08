{
  description = "A very basic flake";
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
  };
  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nur,
      nvf,
      lanzaboote,
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
              ./hosts/themis/configuration.nix
            ];
          };
      };
      homeConfigurations."jack" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = {inherit nur;};
	      modules = [
          nvf.homeManagerModules.default #
          ./users/jack/home.nix 
        ];
      };
    };
}
