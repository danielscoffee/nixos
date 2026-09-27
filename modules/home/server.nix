{ pkgs, ... }:
{
  # Server dotfile selection: keep imports terminal-only.
  imports = [
    ./dev/shell/fish.nix
    ./dev/shell/starship.nix
    ./dev/tools/tools/fzf.nix
    ./dev/tools/tools/tmux.nix
    ./dev/langs/langs.nix
    ./dev/ai/ai.nix
  ];

  home.stateVersion = "24.05";
  nixpkgs.config.allowUnfree = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withPython3 = false;
    withRuby = false;
    waylandSupport = false;
    initLua = builtins.readFile ../../dotfiles/server/nvim/init.lua;
  };

  home.packages = with pkgs; [
    gh
    cmake
    pkg-config
    openssh
    tree-sitter
    zls
    yazi
    wget
    unzip
    zip
    nixd
  ];
}
