{ pkgs, ... }:
{
  programs.fish = {
    enable = true;

    plugins = [
      {
        name = "bass";
        src = pkgs.fishPlugins.bass.src;
      }
    ];

    shellAliases = {
      cd = "z";
      claude-work = "CLAUDE_CONFIG_DIR=~/.claude-work claude";
      nsw = "nvim --suppress-deprecation-warnings";
    };

    functions = {
      fish_greeting = "echo \"\"";

      sc = ''
        sesh connect (sesh list | fzf)
      '';

      nvm = ''
        bass source ~/.nvm/nvm.sh --no-use ';' nvm $argv
      '';

      nvm_find_nvmrc = ''
        bass source ~/.nvm/nvm.sh --no-use ';' nvm_find_nvmrc
      '';

      load_nvm = {
        onVariable = "PWD";
        body = ''
          if not test -f ~/.nvm/nvm.sh
            return
          end

          set -l node_version (nvm version)
          set -l nvmrc_path (nvm_find_nvmrc)
          if test -n "$nvmrc_path"
            set -l nvmrc_node_version (nvm version (cat $nvmrc_path))
            if test "$nvmrc_node_version" = "N/A"
              nvm install (cat $nvmrc_path)
            else if test "$nvmrc_node_version" != "$node_version"
              nvm use $nvmrc_node_version
            end
          end
        '';
      };
    };

    shellInit = ''
      fish_add_path $HOME/go/bin
      fish_add_path $HOME/.local/bin
      fish_add_path $HOME/.cabal/bin
      fish_add_path $HOME/.ghcup/bin
      fish_add_path $HOME/.local/share/pnpm
      fish_add_path $HOME/.fly/bin
      fish_add_path $HOME/.wakatime
      fish_add_path /usr/bin

      set -gx PNPM_HOME $HOME/.local/share/pnpm
      set -gx FLYCTL_INSTALL $HOME/.fly
      set -gx GHCUP_INSTALL_BASE_PREFIX $HOME

      set -e GOROOT
      set -e GOPATH
      set -e GOMODCACHE
      set -e GOBIN

      if test -x /home/linuxbrew/.linuxbrew/bin/brew
        /home/linuxbrew/.linuxbrew/bin/brew shellenv | source
        if test -d (/home/linuxbrew/.linuxbrew/bin/brew --prefix)/share/fish/completions
          set -p fish_complete_path (/home/linuxbrew/.linuxbrew/bin/brew --prefix)/share/fish/completions
        end
        if test -d (/home/linuxbrew/.linuxbrew/bin/brew --prefix)/share/fish/vendor_completions.d
          set -p fish_complete_path (/home/linuxbrew/.linuxbrew/bin/brew --prefix)/share/fish/vendor_completions.d
        end
      end
    '';

    interactiveShellInit = ''
      load_nvm

      if command -q tv
        tv init fish | source
      end

      if command -q terminal-wakatime
        terminal-wakatime init fish | source
      end
    '';
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };
}
