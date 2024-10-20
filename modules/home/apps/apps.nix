{ pkgs, ... }: {
  home.packages = with pkgs; [
    firefox
	scrcpy
	waydroid
    btop
    brightnessctl
    steam
    #bitwarden-desktop
    flameshot
    spotify
    prismlauncher
    vesktop
    pavucontrol
  ];
}
