{pkgs, ... }:
{
  imports = [
    ./env/steam.nix
    ./bluetooth/bluetooth.nix
    ./env/i3.nix
    ./env/config/config.nix
  ];
  programs.thunar.plugins = with pkgs.xfce; [
  thunar-archive-plugin
  thunar-volman
];

}
