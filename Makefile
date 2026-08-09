.PHONY: check fmt rebuild build build-wsl hardware update clean dotfile setup

FLAKE ?= .
SOURCE_FLAKE ?= path:$(abspath $(FLAKE))
HOST ?= default

check:
	@nix flake check --no-build "$(SOURCE_FLAKE)"
	@nix fmt -- --ci

fmt:
	@nix fmt

rebuild:
	@sudo nixos-rebuild switch --flake "$(FLAKE)#$(HOST)"

build:
	@nix build "$(SOURCE_FLAKE)#nixosConfigurations.$(HOST).config.system.build.toplevel"

build-wsl:
	@nix build "$(SOURCE_FLAKE)#nixosConfigurations.wsl.config.system.build.toplevel"

hardware:
	@sudo nixos-generate-config --show-hardware-config > hosts/default/hardware-configuration.nix
	@echo "Regenerated hosts/default/hardware-configuration.nix for THIS machine."

update:
	@nix flake update --flake "$(FLAKE)"

clean:
	@sudo nix-collect-garbage --delete-older-than 1d
	@sudo nix-collect-garbage -d

dotfile:
	@cp -r ./dotfiles/i3 ./dotfiles/i3status ./dotfiles/rofi $$HOME/.config/

setup: hardware rebuild dotfile
