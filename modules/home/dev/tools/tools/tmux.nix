{ pkgs, ... }: {
  programs.tmux = {
    enable = true;
    mouse = true;
    plugins = with pkgs.tmuxPlugins; [ rose-pine ];
    extraConfig = ''
      set -g @plugin 'rose-pine/tmux'
      set -g @rose_pine_variant 'main'
      set -g @rose_pine_bar_bg_disable 'on'
      set -g @rose_pine_only_windows 'on'
      set -g @rose_pine_disable_active_window_menu 'on'
      set -g @rose_pine_default_window_behavior 'on'
      set -g @rose_pine_show_current_program 'on'
      set-option -g status-position top
      bind M-c attach-session -c "#{pane_current_path}"
    '';
    keyMode = "vi";
    prefix = "M-s";
  };
}

