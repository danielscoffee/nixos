{ pkgs, ... }:
{
  imports = [
    ./apps/obs.nix
    ./apps/dunst.nix
  ];

  xdg.configFile."television" = {
    source = ../../../dotfiles/television;
    recursive = true;
  };

  home.packages = with pkgs; [
    anydesk
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
    # BUG: ELECTRON EOL
    # bitwarden-desktop
    discord
    flameshot
    droidcam
    spotify
    pavucontrol
  ];
}
