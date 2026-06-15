{ pkgs, ... }: {
  imports = [
    ./langs/hs.nix
    ./langs/go.nix
    ./langs/js.nix
    ./langs/lua.nix
  ];
  home.packages = with pkgs; [
    #jdk8
    jdk21
    #jdk17
    dotnet-sdk
    lua
    gcc
    rustc
    python3
    zig
    cargo
  ];
}
