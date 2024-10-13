{ pkgs, ... }: {
  imports = [ ./langs/go.nix ./langs/js.nix ];
  home.packages = with pkgs; [
    jdk8
    jdk21
    jdk17
    lua
    gcc
    rustc
    python3
    zig
    cargo
  ];
}
