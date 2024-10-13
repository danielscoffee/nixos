{ pkgs, ... }: {
  imports = [ ./tools/fzf.nix ./tools/kitty.nix ./tools/tmux.nix ];
  home.packages = with pkgs; [
    # Git
    git
    gh
    # CLI Tools
    neovim
    gnumake
    yazi
    neofetch
    # GUI Tools
    postman
    # Extension
    rofi
    # Requests
    curl
    wget
  ];
}
