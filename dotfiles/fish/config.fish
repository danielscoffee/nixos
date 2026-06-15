if status is-interactive
    starship init fish | source
    load_nvm
    zoxide init fish | source
end

function sc
	sesh connect $(sesh list | fzf)
end

alias cd z

alias nsw "nvim --suppress-deprecation-warnings"

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

set -gx PATH $PATH $HOME/go/bin
set -U | grep -E "GOROOT|GOPATH|GOMODCACHE|GOBIN"
set -e GOROOT
set -e GOPATH
set -e GOMODCACHE
set -e GOBIN

set -q GHCUP_INSTALL_BASE_PREFIX[1]; or set GHCUP_INSTALL_BASE_PREFIX $HOME ; set -gx PATH $HOME/.cabal/bin /home/daniel/.ghcup/bin $PATH # ghcup-env
export PATH="$HOME/.local/bin:$PATH"


# pnpm
set -gx PNPM_HOME "/home/daniel/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end


fish_add_path /usr/bin/

export FLYCTL_INSTALL="/home/daniel/.fly"
export PATH="$FLYCTL_INSTALL/bin:$PATH"

# terminal-wakatime setup
set -gx PATH "$HOME/.wakatime" $PATH
if status is-interactive
    terminal-wakatime init fish | source
end
