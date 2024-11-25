{ pkgs, ... }: {
  services.xserver = {
    enable = true;
    desktopManager.xterm.enable = false;
    windowManager.i3 = {
      package = pkgs.i3-gaps;
      enable = true;
      extraPackages = with pkgs; [ dmenu i3status i3lock ];
    };
  };

  services = { displayManager.defaultSession = "none+i3"; };

  programs.dconf.enable = true;
}
