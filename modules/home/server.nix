{ pkgs, ... }:
{
  # Server dotfile selection: keep imports terminal-only.
  imports = [
    ./dev/shell/fish.nix
    ./dev/shell/starship.nix
    ./dev/tools/tools/fzf.nix
    ./dev/tools/tools/tmux.nix
  ];

  home.stateVersion = "24.05";

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
    gcc
    cmake
    pkg-config
    python3
    nodejs
    go
    ripgrep
    fd
    jq
    unzip
    zip
    nixfmt
    nixd
  ];
}
