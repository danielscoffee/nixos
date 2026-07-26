{ pkgs, ... }:
{
  imports = [
    ./ai/codex.nix
    ./ai/claude-code.nix
    ./ai/hermes.nix
    ./ai/pi.nix
  ];
  programs.hermes-workstation = {
    enable = true;
    provider = "openai-codex";
    model = "gpt-5.6-sol";
  };

  home.packages = with pkgs; [
    rtk
  ];
}
