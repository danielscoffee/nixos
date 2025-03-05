{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    profiles = {
      default = { 
        extensions = with pkgs.vscode-extensions; [
          jnoortheen.nix-ide
          vscodevim.vim
          golang.go
          ziglang.vscode-zig
          github.github-vscode-theme 
          yzhang.markdown-all-in-one
        ];
        userSettings = {
          "window.titleBarStyle" = "native";
          "editor.fontSize" = 18;
          "markdown.extension.preview.autoShowNavigationBar" = false;
          "workbench.colorTheme" = "GitHub Dark Default";
          "workbench.preferredDarkColorTheme" = "GitHub Dark Default";
          "workbench.preferredHighContrastColorTheme" = "GitHub Dark Default";
          "workbench.sideBar.location" = "right";
          "window.menuBarVisibility" = "hidden";
          "workbench.activityBar.location" = "hidden";
          "editor.renderWhitespace" = "none";
          "editor.cursorStyle" = "block";

          "nix.enableLanguageServer" = true;
          "nix.serverPath" = "nixd";
          "nix.formatterPath" = "nixfmt";
          "nix.serverSettings" = {
            "nixd" = {
              "formatting" = {
                "command" = [ "nixpkgs-fmt" ];
              };
            };
          };
        };
      };
    };
  };
}
