{ pkgs, ... }: {
  programs.pi-coding-agent = {
    enable = true;

    extraPackages = with pkgs; [
      nil
      basedpyright
      gopls
      jdt-language-server
      typescript
      nodejs
      bun
      git
      ripgrep
      fd
      jq
    ];

    settings = {
      defaultProjectTrust = "ask";

      packages = [
        "npm:pi-caveman@1.0.7"
        "npm:pi-superpowers@0.2.0"
        "npm:pi-web-access@0.10.7"
        "npm:pi-subagents@0.28.0"
        "npm:pi-lens@3.8.50"
        "npm:pi-powerline-footer@0.6.1"
        "npm:@ayulab/pi-rewind@0.3.1"
      ];
    };
  };
}
