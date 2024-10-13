{ pkgs, ... }: {
  services.xserver = {
    enable = true;
    desktopManager = { xterm.enable = false; };
    displayManager = { defaultSession = "none+i3"; };
    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [ dmenu i3status i3lock ];
    };
  };

  services.xserver.windowManager.i3.package = pkgs.i3-gaps;
  programs.dconf.enable = true;

}
