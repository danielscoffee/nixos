{
  programs.kitty = {
    enable = true;
    environment.POWERLINE_NERD_FONTS = "1";
    font = {
      name = "FiraCode Nerd Font Mono";
      size = 20;
    };
    keybindings = {
      "enter" = "send_text all \\x0d";
      "shift+enter" = "send_text all \\x1b[13;2u";
    };
    themeFile = "duckbones";
  };
}
