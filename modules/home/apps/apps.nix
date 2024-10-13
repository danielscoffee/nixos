{ pkgs, ... }: {
  home.packages = with pkgs; [
    firefox
    btop
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
