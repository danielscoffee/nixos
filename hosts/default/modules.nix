{ inputs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/system/system.nix
    ./config/daniel.nix
    ./config/docker.nix
	./config/boot.nix
    inputs.home-manager.nixosModules.home-manager
  ];
}
