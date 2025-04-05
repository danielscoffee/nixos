{ pkgs, ... }: {
  imports = [
    ./apps/obs.nix 
    ./apps/dunst.nix
  ];
  home.packages = with pkgs; [
    firefox
	jetbrains-toolbox
    unzip
    television
    anki
    flatpak
    gearlever
    heroic
    shotcut
    btop
    brightnessctl
    obsidian
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
