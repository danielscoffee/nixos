{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    initExtra =
      "  export PATH=`go env GOPATH`/bin/:$PATH\n  source ~/nixos/headline.zsh-theme\n  if [ -z \"$TMUX\" ]\n  then\n	tmux attach -t TMUX  || tmux new -s TMUX\n  fi\n  ";
    oh-my-zsh = {
      enable = true;
      plugins = [ "fzf" "git" "web-search" "tmux" "golang" ];
    };
  };
}
