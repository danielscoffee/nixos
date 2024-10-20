{ pkgs, ... }: {
  programs.zsh.enable = true;
  users.users.daniel = {
    isNormalUser = true;
    shell = pkgs.zsh;
    description = "daniel";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
  };
}
