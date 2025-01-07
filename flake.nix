{
  description = "FLAKES";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

	ghostty = {
      url = "github:ghostty-org/ghostty";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ghostty, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackage.${system};
    in {
      nixosConfigurations = {
        default = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
		  	./hosts/default/configuration.nix 
			{
          	environment.systemPackages = [
            	ghostty.packages.x86_64-linux.default
          	];
        	}
		  ];
        };
      };

      homeConfigurations = {
        daniel = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs { inherit system; };
          modules = [ ./modules/home/home.nix ];
        };
      };
    };
}
