{
  config,
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

  environment.systemPackages = with pkgs; [
    btop
    curl
    gitMinimal
    gnumake
    tmux
    vim
  ];
}
