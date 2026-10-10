{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:
{
  # Standalone profile: do not import the desktop system or Home Manager modules.
  imports = [ (modulesPath + "/profiles/minimal.nix") ];

  networking = {
    networkmanager.enable = true;
    firewall = {
      enable = true;
      interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts =
        config.services.openssh.ports;
    };
  };

  services = {
    tailscale = {
      enable = true;
      openFirewall = true;
    };

    openssh = {
      enable = true;
      openFirewall = false;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
        X11Forwarding = false;
      };
    };

    logind.settings.Login = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
      HandleLidSwitchDocked = "ignore";
    };

    # The minimal profile disables log rotation; keep it for a persistent server.
    logrotate.enable = true;
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Keep the small NVMe from filling up with old generations and stale /tmp.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;
  boot.tmp.cleanOnBoot = true;

  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  # Tailscale SSH bypasses PAM, so pam_systemd never sets XDG_RUNTIME_DIR and
  # setSocketVariable silently leaves DOCKER_HOST empty. Must run before it.
  environment.extraInit = lib.mkBefore ''
    if [ -z "$XDG_RUNTIME_DIR" ] && [ -d "/run/user/$(id -u)" ]; then
      export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    fi
  '';

  environment.systemPackages = with pkgs; [
    btop
    curl
    docker-compose
    gitMinimal
    gnumake
    kitty.terminfo
    tmux
    vim
  ];
}
