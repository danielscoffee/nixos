{ pkgs, ... }: {
  programs.tmux = {
    enable = true;
    mouse = true;
    plugins = with pkgs.tmuxPlugins; [ rose-pine ];
    extraConfig =
      "set -g @plugin 'rose-pine/tmux'\n set -g @rose_pine_variant 'main'\n set -g @rose_pine_bar_bg_disable 'on' \n 
	  set -g @rose_pine_only_windows 'on' \n set -g @rose_pine_disable_active_window_menu 'on' \n set -g @rose_pine_default_window_behavior 'on' \n set -g @rose_pine_show_current_program 'on'
	  \n set-option -g status-position top\n	bind M-c attach-session -c \"#{pane_current_path}\"\n";
    keyMode = "vi";
    prefix = "M-s";
  };
}

