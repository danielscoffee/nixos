{ pkgs, ... }:
{
	imports = [
		./langs/go.nix
];
	home.packages = with pkgs; [
		 jdk8
		 jdk21
		 jdk17
		 nodejs
		 lua
		 gcc
		 rustc
		 python3
		 zig
		 cargo
	];
}
