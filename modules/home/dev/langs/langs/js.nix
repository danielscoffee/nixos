{ pkgs, ... }: { home.packages = with pkgs; [ typescript 
	nodejs
nest-cli yarn ]; }
