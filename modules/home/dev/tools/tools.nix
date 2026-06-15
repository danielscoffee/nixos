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
    ./tools/fzf.nix
    ./tools/kitty.nix
    ./tools/tmux.nix
    ./tools/vscode.nix
  ];

  home.file.".local/share/nvim/site/parser/norg.so".source =
    "${pkgs.tree-sitter-grammars.tree-sitter-norg}/parser";
  home.file.".local/share/nvim/site/parser/norg_meta.so".source =
    "${pkgs.tree-sitter-grammars.tree-sitter-norg-meta}/parser";

  home.packages = with pkgs; [
    # Git
    git
    gh
    # CLI Tools
    neovimWithLibstdcpp
    tree-sitter
    openssl
    gnumake
    yazi
    fastfetch
    # GUI Tools
    postman
    # Extension
    rofi
    # Requests
    curl
    wget
    # Nix
    nixfmt
    nixd
    # LSPs
    zls
    gopls
  ];
}
