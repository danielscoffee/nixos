{ pkgs, ... }: {
  programs.tmux = {
    enable = true;
    mouse = true;
    plugins = with pkgs.tmuxPlugins; [ tokyo-night-tmux ];
    extraConfig =
      "	set -g @tokyo-night-tmux_show_path 1\n	set -g @tokyo-night-tmux_path_format relative\n	set-option -g status-position top\n	bind M-c attach-session -c \"#{pane_current_path}\"\n";

    keyMode = "vi";
    prefix = "M-s";
  };
}
