{ pkgs, ... }: {
  imports = [
  	./apps/obs.nix
  ];
  home.packages = with pkgs; [
    firefox
	#kicad
	steam
    btop
    brightnessctl
    bitwarden-desktop
	discord
    flameshot
	droidcam
    spotify
    prismlauncher
    vesktop
    pavucontrol
  ];
}
