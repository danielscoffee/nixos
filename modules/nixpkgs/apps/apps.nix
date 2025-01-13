{
  imports = [ ./apps/thunar.nix ];

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

}
