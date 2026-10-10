{ lib, pkgs, ... }:
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
    # Keep ~/.config/nvim free for the checkout below; HM's provider
    # settings load through the wrapper instead.
    sideloadInitLua = true;
  };

  # Same nvim config as the other machines: a writable checkout, so
  # lazy.nvim can update lazy-lock.json and edits can be pushed back.
  home.activation.nvimConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    nvim_dir="$HOME/.config/nvim"
    if [ ! -e "$nvim_dir/.git" ]; then
      if [ -z "$(ls -A "$nvim_dir" 2>/dev/null)" ]; then
        run ${pkgs.git}/bin/git clone https://github.com/danielscoffee/nvim-config "$nvim_dir" \
          || warnEcho "nvim-config clone failed; it is retried on the next activation"
      else
        warnEcho "$nvim_dir has files but no git checkout; leaving it alone"
      fi
    fi
  '';

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
