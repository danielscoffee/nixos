.PHONY: check fmt rebuild build build-wsl hardware update clean dotfile setup

FLAKE ?= .
SOURCE_FLAKE ?= path:$(abspath $(FLAKE))
HOST ?= loqe

check:
	@bash tests/hardware.sh
	@nix flake check --no-build "$(SOURCE_FLAKE)"
	@nix fmt -- --ci --excludes 'hosts/*/hardware-configuration.nix'

fmt:
	@nix fmt -- --excludes 'hosts/*/hardware-configuration.nix'

rebuild:
	@sudo nixos-rebuild switch --flake "$(SOURCE_FLAKE)#$(HOST)"

build:
	@nix build "$(SOURCE_FLAKE)#nixosConfigurations.$(HOST).config.system.build.toplevel"

build-wsl:
	@nix build "$(SOURCE_FLAKE)#nixosConfigurations.wsl.config.system.build.toplevel"

hardware:
	@test ! -L "hosts/$(HOST)/hardware-configuration.nix" || { echo "Refusing to replace a symlinked hardware configuration."; exit 1; }
	@tmp=$$(mktemp "hosts/$(HOST)/.hardware-configuration.XXXXXX") || exit 1; \
	trap 'rm -f "$$tmp"' EXIT; \
	sudo nixos-generate-config --show-hardware-config > "$$tmp" && \
	chmod 644 "$$tmp" && \
	mv "$$tmp" "hosts/$(HOST)/hardware-configuration.nix"
	@echo "Regenerated hosts/$(HOST)/hardware-configuration.nix for THIS machine."

update:
	@nix flake update --flake "$(FLAKE)"

clean:
	@sudo nix-collect-garbage --delete-older-than 1d
	@sudo nix-collect-garbage -d

dotfile:
	@cp -r ./dotfiles/i3 ./dotfiles/i3status ./dotfiles/rofi $$HOME/.config/

setup: hardware rebuild dotfile
