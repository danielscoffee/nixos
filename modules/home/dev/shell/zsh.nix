{
  programs.zsh = {
	enable = true;
	enableCompletion = true;
	autosuggestion.enable = true;
	syntaxHighlighting.enable = true;
	initExtra = ''
		source ~/nixos/headline.zsh-theme
		if [ -z "$TMUX" ]
		then
			tmux attach -t TMUX || tmux new -s TMUX
		fi
	'';
	oh-my-zsh = {
	  enable = true;
	  plugins = [ 
	  	"git"
	  	"web-search"
		"tmux"
		"golang"
	  ];
	};
  };
 }
