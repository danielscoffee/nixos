{ pkgs, ... }:
{
  imports = [
    ./dev/dev.nix
    ./apps/apps.nix
  ];

  home.username = "daniel";
  home.homeDirectory = "/home/daniel";

  home.stateVersion = "24.05";

  gtk = {
    enable = true;
    colorScheme = "dark";
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    # GTK 4/libadwaita uses colorScheme, not GTK 2/3 theme CSS.
    gtk4.theme = null;
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk3";
    style.name = "adwaita-dark";
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    setSessionVariables = true;
    documents = null;
    download = null;
    music = null;
    pictures = null;
    projects = null;
    publicShare = null;
    templates = null;
    videos = null;
  };

  nixpkgs.config.allowUnfree = true;

  programs.home-manager.enable = true;
}
