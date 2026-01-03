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
  };
  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nur,
      nvf,
      ...
    }:
    {
      nixosConfigurations = {
        nixos =
          let
            username = "jack";
            system = "x86_64-linux";
            specialArgs = { inherit username system; };
          in
          nixpkgs.lib.nixosSystem {
            modules = [
              nur.modules.nixos.default
              # nur.legacyPackages."${system}".repos.iopq.modules.xraya
              ./nixos/configuration.nix
              # home-manager.nixosModules.home-manager
              # {
              #   home-manager.extraSpecialArgs = { inherit nur; };
              #   # extraSpecialArgs = {inherit inputs; };
              #   # home-manager.nixpkgs.overlays = [ nur.overlays.default ];
              #   #  nixpkgs.overlays = [ (final: prev:  nur.overlays.default) ];
              #   home-manager.useUserPackages = true;
              #   home-manager.users.${username} = ./users/${username}/home.nix;
              # }
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
