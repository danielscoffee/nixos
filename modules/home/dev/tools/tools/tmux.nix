{ pkgs, ... }:
{
	programs.tmux = {
		enable = true;
		mouse = true;
		plugins = with pkgs.tmuxPlugins; [
			tokyo-night-tmux
		];
		extraConfig = ''
			set -g @tokyo-night-tmux_show_path 1
			set -g @tokyo-night-tmux_path_format relative
			set-option -g status-position top
			bind M-c attach-session -c "#{pane_current_path}"
		'';

		keyMode = "vi";
		prefix = "M-s";
	};
}
