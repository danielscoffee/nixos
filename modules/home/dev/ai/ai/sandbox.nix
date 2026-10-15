# Generic bubblewrap sandbox for the AI coding agents.
#
# `script` is `ai-sandbox`, which runs any command confined; `wrap`
# rebuilds a package so its main program always launches through it.
# Inside the sandbox the filesystem is read-only except the project
# (git top-level of the cwd, else the cwd itself), a fresh /tmp and the
# paths listed as rw; $HOME is a private persistent directory
# (~/.local/share/ai-sandbox/home), so keys and tokens in the real home
# stay invisible unless listed as ro or rw; PID, IPC, UTS and user
# namespaces are fresh and the network is shared. Nested launches run
# directly, and AI_SANDBOX=0 bypasses the sandbox altogether.
{ lib, pkgs }:
let
  script = pkgs.writeShellApplication {
    name = "ai-sandbox";
    runtimeInputs = with pkgs; [
      bubblewrap
      coreutils
      git
    ];
    text = ''
      usage() {
        cat >&2 <<'EOF'
      usage: ai-sandbox [-w PATH]... [-r PATH]... [--] COMMAND [ARG]...

      Runs COMMAND confined by bubblewrap. The filesystem is read-only
      except the project (git top-level of the current directory, else the
      directory itself), /tmp and the PATHs given with -w; -r PATH exposes
      a path read-only. $HOME is a private persistent directory, so nothing
      in the real home is visible unless listed; ~/.gitconfig, ~/.config/git
      and ~/.local/bin are always read-only. Relative PATHs are taken from
      $HOME. PID, IPC and user namespaces are fresh; the network is shared.

        AI_SANDBOX=0    run COMMAND directly, without a sandbox
        AI_SANDBOX_RW   extra -w paths, colon-separated
        AI_SANDBOX_RO   extra -r paths, colon-separated
      EOF
        exit 64
      }

      rw=()
      ro=(.gitconfig .config/git .local/bin)
      while [ $# -gt 0 ]; do
        case $1 in
          -w) [ $# -ge 2 ] || usage; rw+=("$2"); shift 2 ;;
          -r) [ $# -ge 2 ] || usage; ro+=("$2"); shift 2 ;;
          --) shift; break ;;
          -*) usage ;;
          *) break ;;
        esac
      done
      [ $# -gt 0 ] || usage

      # Already confined (a tool launching another tool) or opted out.
      if [ "''${AI_SANDBOX:-1}" = 0 ] || [ "''${AI_SANDBOX_ACTIVE:-}" = 1 ]; then
        exec "$@"
      fi

      IFS=: read -ra extra <<<"''${AI_SANDBOX_RW:-}"
      rw+=("''${extra[@]}")
      IFS=: read -ra extra <<<"''${AI_SANDBOX_RO:-}"
      ro+=("''${extra[@]}")

      # True when $2 is $1 or inside it.
      within() {
        [ "$1" = / ] && return 0
        case $2 in "$1" | "$1"/*) return 0 ;; esac
        return 1
      }
      abs() {
        case $1 in /*) printf '%s\n' "$1" ;; *) printf '%s\n' "$HOME/$1" ;; esac
      }

      home=$(realpath "$HOME")
      cwd=$(pwd -P)
      toplevel=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true)
      if [ -n "$toplevel" ] && ! within "$toplevel" "$home"; then
        root=$toplevel
        # Linked worktrees and submodules keep their object store elsewhere.
        gitdir=$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)
        if [ -n "$gitdir" ] && ! within "$root" "$gitdir"; then
          rw+=("$gitdir")
        fi
      else
        root=$cwd
      fi
      if within "$root" "$home"; then
        echo "ai-sandbox: $root contains \$HOME; cd into a project or set AI_SANDBOX=0" >&2
        exit 64
      fi

      shadow=''${XDG_DATA_HOME:-$HOME/.local/share}/ai-sandbox/home
      mkdir -p "$shadow"

      args=(
        --ro-bind / /
        --dev /dev
        --proc /proc
        --tmpfs /tmp
        --bind "$shadow" "$HOME"
      )
      # Hide the agent sockets (ssh, gpg, dbus, keyring) of the session.
      run=/run/user/$(id -u)
      if [ -d "$run" ]; then
        args+=(--tmpfs "$run")
      fi
      if [ -n "''${XDG_RUNTIME_DIR:-}" ] && [ "$XDG_RUNTIME_DIR" != "$run" ] && [ -d "$XDG_RUNTIME_DIR" ]; then
        args+=(--tmpfs "$XDG_RUNTIME_DIR")
      fi
      args+=(--bind "$root" "$root")
      for p in "''${ro[@]}"; do
        [ -n "$p" ] || continue
        p=$(abs "$p")
        args+=(--ro-bind-try "$p" "$p")
      done
      for p in "''${rw[@]}"; do
        [ -n "$p" ] || continue
        p=$(abs "$p")
        args+=(--bind-try "$p" "$p")
      done
      # No --new-session: the TUIs need the controlling terminal, and the
      # kernel's legacy TIOCSTI is off, so that is safe here.
      args+=(
        --unshare-all
        --share-net
        --die-with-parent
        --chdir "$cwd"
        --setenv AI_SANDBOX_ACTIVE 1
        --unsetenv SSH_AUTH_SOCK
        --unsetenv GPG_AGENT_INFO
        --unsetenv DBUS_SESSION_BUS_ADDRESS
        --unsetenv TMUX
        --unsetenv TMUX_PANE
      )
      exec bwrap "''${args[@]}" -- "$@"
    '';
  };
in
{
  inherit script;

  # Replace the main program of `package` with one that runs inside the
  # sandbox. rw and ro list paths (relative to $HOME, or absolute) to
  # expose; env gives variable defaults the launcher exports first, as
  # shell text, so "$HOME/x" expands at run time.
  wrap =
    {
      package,
      exe ? package.meta.mainProgram,
      rw ? [ ],
      ro ? [ ],
      env ? { },
    }:
    let
      flags = lib.escapeShellArgs (
        lib.concatMap (p: [
          "-w"
          p
        ]) rw
        ++ lib.concatMap (p: [
          "-r"
          p
        ]) ro
      );
      exports = lib.concatStrings (
        lib.mapAttrsToList (k: v: '': "''${${k}:=${v}}"; export ${k}'' + "\n") env
      );
    in
    pkgs.symlinkJoin {
      name = "${lib.getName package}-sandboxed-${lib.getVersion package}";
      inherit (package) version meta;
      paths = [ package ];
      passthru = (package.passthru or { }) // {
        unwrapped = package;
      };
      postBuild = ''
        rm "$out/bin/${exe}"
        cat > "$out/bin/${exe}" <<'EOF'
        #!${pkgs.runtimeShell}
        ${exports}exec ${script}/bin/ai-sandbox ${flags} -- ${package}/bin/${exe} "$@"
        EOF
        chmod +x "$out/bin/${exe}"
      '';
    };
}
