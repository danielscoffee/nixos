{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initExtra =
      ''
	  export PATH=`go env GOPATH`/bin/:$PATH
	  source ~/nixos/headline.zsh-theme
	  tmux source ~/.config/tmux/tmux.conf
	  '';
    oh-my-zsh = {
      enable = true;
      plugins = [ "fzf" "git" "web-search" "tmux" "golang" ];
    };
  };
}
