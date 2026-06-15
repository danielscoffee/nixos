
{ pkgs, ... }: {
  home.packages = with pkgs; [ luaPackages.luarocks-nix lua ];
}
