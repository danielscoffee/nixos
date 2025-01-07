{ pkgs, ... }: {
  imports = [ ./apps/obs.nix ./apps/dunst.nix ];
  home.packages = with pkgs; [
    firefox
	heroic
	shotcut
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
