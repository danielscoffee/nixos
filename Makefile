rebuild:
	@sudo nixos-rebuild switch --flake ./#default

hardware:
	@sudo nixos-generate-config --show-hardware-config > hosts/default/hardware-configuration.nix
	@echo "Regenerated hosts/default/hardware-configuration.nix for THIS machine."

update:
	@nix flake update --flake ./

clean:
	@sudo nix-collect-garbage --delete-older-than 1d
	@sudo nix-collect-garbage -d

dotfile:
	@cp -r ./dotfiles/. $$HOME/.config 

setup:
	@make hardware
	@make rebuild
	@make dotfile
