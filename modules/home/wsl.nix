{ pkgs, ... }:
let
  neovimWithLibstdcpp = pkgs.symlinkJoin {
    name = "neovim-with-libstdcpp";
    paths = [ pkgs.neovim ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/nvim --prefix LD_LIBRARY_PATH : ${
        pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]
      }
    '';
  };
in
{
  imports = [
    ./dev/shell/shell.nix
    ./dev/ai/ai.nix
    ./dev/langs/langs.nix
    ./dev/tools/tools/fzf.nix
    ./dev/tools/tools/tmux.nix
  ];

  home.username = "daniel";
  home.homeDirectory = "/home/daniel";
  home.stateVersion = "24.05";

  nixpkgs.config.allowUnfree = true;

  programs.home-manager.enable = true;

  home.file.".local/share/nvim/site/parser/norg.so".source =
    "${pkgs.tree-sitter-grammars.tree-sitter-norg}/parser";
  home.file.".local/share/nvim/site/parser/norg_meta.so".source =
    "${pkgs.tree-sitter-grammars.tree-sitter-norg-meta}/parser";

  home.packages = with pkgs; [
    git
    gh
    neovimWithLibstdcpp
    tree-sitter
    curl
    wget
    ripgrep
    fd
    jq
    yazi
    fastfetch
    nixfmt
    nil
    nixd
  ];
}
