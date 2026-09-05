{ pkgs, ... }: {
  home.packages = with pkgs; [
    lua51Packages.luarocks-nix
    lua5_1
  ];
}
