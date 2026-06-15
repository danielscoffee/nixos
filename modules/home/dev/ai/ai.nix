{ pkgs, ... }:
{
  imports = [
    ./ai/codex.nix
    ./ai/claude-code.nix
    ./ai/pi.nix
  ];
  home.packages = with pkgs; [
    rtk
  ];
}
