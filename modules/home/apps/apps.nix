{ pkgs, ... }:
{
	home.packages = with pkgs; [
		firefox
	 	brightnessctl
		steam
		aseprite
		bitwarden-desktop
		flameshot
		spotify
		prismlauncher
		vesktop
		pavucontrol
	];
}
