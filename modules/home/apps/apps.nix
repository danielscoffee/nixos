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

    shotcut
    btop
    brightnessctl
    obsidian
    bitwarden-desktop
    discord
    flameshot
    droidcam
    spotify
    vesktop
    pavucontrol
  ];
}
