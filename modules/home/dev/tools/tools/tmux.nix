{ ... }: {
  programs.tmux = {
    enable = true;
    mouse = true;
    extraConfig = ''
            set-option -g status-position top
      	  set -g status-bg black
      	  set -g status-fg white
            bind M-c attach-session -c "#{pane_current_path}"
    '';
    keyMode = "vi";
    prefix = "M-s";
  };
}

