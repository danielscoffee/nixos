{ pkgs, ... }:
{
	programs.nix-ld = {
		enable = true;
		libraries = with pkgs; [
			dart-sass
		];
	};
}
