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

  xdg.configFile."flameshot/flameshot.ini" = {
    force = true;
    text = ''
      [General]
      useX11LegacyScreenshot=true
    '';
  };

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
    # BUG: ELECTRON EOL
    # bitwarden-desktop
    discord
    flameshot
    droidcam
    spotify
    pavucontrol
  ];
}
