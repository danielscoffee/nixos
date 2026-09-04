{
  imports = [
    ./dev/dev.nix
    ./apps/apps.nix
  ];

  home.username = "daniel";
  home.homeDirectory = "/home/daniel";

  home.stateVersion = "24.05";

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
