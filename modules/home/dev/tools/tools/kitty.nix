{
  programs.kitty = {
    enable = true;
    font = {
      name = "Fira Code";
      size = 20;
    };
    keybindings = {
      "enter" = "send_text all \\x0d";
      "shift+enter" = "send_text all \\x1b[13;2u";
    };
    themeFile = "duckbones";
  };
}
