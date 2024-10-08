{
  imports = [
  	./dev/dev.nix
	./apps/apps.nix
	./fonts/fonts.nix
  ];

  home.username = "daniel";
  home.homeDirectory = "/home/daniel";

  home.stateVersion = "24.05"; 

  nixpkgs.config.allowUnfree = true;

  programs.home-manager.enable = true;
}
