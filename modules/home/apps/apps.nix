{ pkgs, ... }: {
  imports = [ ./apps/obs.nix ./apps/dunst.nix ];
  home.packages = with pkgs; [
    firefox
    #kicad
    btop
	vlc
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
