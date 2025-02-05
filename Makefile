rebuild:
	@sudo nixos-rebuild switch --flake ./#default

update:
	@nix flake update --flake ./

clean:
	@sudo nix-collect-garbage --delete-older-than 1d
	@sudo nix-collect-garbage -d

dotfile:
	@cp -r ./dotfiles/. $$HOME/.config 

setup: 
	@make rebuild
	@make dotfile
