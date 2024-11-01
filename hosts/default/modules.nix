{ inputs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/system/system.nix
    ../../modules/nix-ld.nix
	./config/k8s.nix
    ./config/daniel.nix
    ./config/docker.nix
	./config/boot.nix
    inputs.home-manager.nixosModules.home-manager
  ];
}
