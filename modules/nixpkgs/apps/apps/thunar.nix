{ pkgs, ... }: {
  programs.xfce.thunar = {
	enable = true;
	programs.thunar.plugins = with pkgs.xfce; [
		thunar-archive-plugin
			thunar-volman
	];
  };
  services.gvfs.enable = true;
}
