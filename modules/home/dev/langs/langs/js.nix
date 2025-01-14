{ pkgs, ... }: { home.packages = with pkgs; [ typescript nodejs_23 nest-cli yarn ]; }
