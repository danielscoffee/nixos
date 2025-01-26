{ pkgs, ... }: {
  programs.zsh.enable = true;
  programs.fish.enable = true;
  services.logmein-hamachi.enable = true;
  services.flatpak.enable = true;
  xdg.portal.enable = true;
  users.users.daniel = {
    isNormalUser = true;
    shell = pkgs.fish;
    description = "daniel";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
  };
}
