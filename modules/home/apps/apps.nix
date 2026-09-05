{ pkgs, ... }:
{
  imports = [
    ./apps/obs.nix
    ./apps/dunst.nix
    ./apps/chatgpt.nix
    ./apps/grok-bot.nix
  ];

  xdg.configFile."television" = {
    source = ../../../dotfiles/television;
    recursive = true;
  };

  xdg.configFile."flameshot/flameshot.ini" = {
    force = true;
    text = ''
      [General]
      useX11LegacyScreenshot=true
    '';
  };

  home.packages = with pkgs; [
    proton-vpn
    stoat-desktop
    mangohud
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
	chromium
    discord
    flameshot
    droidcam
    spotify
    pavucontrol
  ];
}
