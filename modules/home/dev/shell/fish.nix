{
  programs.fish = {
    enable = true;
    shellInit = ''
                  starship init fish | source
            	  set PATH $PATH (go env GOPATH)/bin
            	  set -x GOPATH (go env GOPATH)
            	  function fish_greeting
            		echo ""
            	  end
      		if status is-interactive
      		and not set -q TMUX
      			if tmux has-session -t home
      			exec tmux attach-session -t home
      			else
      				tmux new-session -s home
      			end
      		end
    '';
  };
}
