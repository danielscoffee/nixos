{ pkgs, ... }: {
	home.packages = with pkgs; [ 
		dart-sass
		typescript
		nodejs
		nest-cli
	];
}
