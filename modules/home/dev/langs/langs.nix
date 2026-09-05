{ pkgs, ... }: {
  imports = [
    ./langs/hs.nix
    ./langs/go.nix
    ./langs/js.nix
    ./langs/lua.nix
  ];
  home.packages = with pkgs; [
    jdk25
    dotnet-sdk
    gcc
    rustc
    python3
    zig
    cargo
  ];
}
