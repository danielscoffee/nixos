{
  programs.fish = {
    enable = true;
    shellInit = ''
      starship init fish | source
	  set PATH $PATH (go env GOPATH)/bin
	  set -x GOPATH (go env GOPATH)
    '';
  };
}
