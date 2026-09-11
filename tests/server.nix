{ flake }:
let
  inherit (flake.inputs.nixpkgs) lib;
  server = flake.nixosConfigurations.server;
  config =
    (server.extendModules {
      modules = [
        {
          # Evaluate the real host without depending on one laptop's disks.
          disabledModules = [ ../hosts/server/hardware-configuration.nix ];
          boot.isContainer = true;
          boot.loader.systemd-boot.enable = lib.mkForce false;
        }
      ];
    }).config;
in
assert flake.nixosConfigurations ? server;
assert !server.config.boot.isContainer;
assert config.networking.hostName == "server";
assert config.users.users.daniel.isNormalUser;
assert lib.all (group: lib.elem group config.users.users.daniel.extraGroups) [
  "wheel"
  "networkmanager"
];
assert config.services.tailscale.enable && config.services.openssh.enable;
assert config.networking.networkmanager.enable;
assert config.networking.firewall.enable;
assert !config.services.openssh.openFirewall;
assert config.networking.firewall.allowedTCPPorts == [ ];
assert config.networking.firewall.backend == "iptables";
assert config.services.openssh.ports == [ 22 ];
assert lib.hasInfix
  "iptables -w -A nixos-fw -s 192.168.100.0/24 -p tcp --dport 22 -j nixos-fw-accept\n"
  config.networking.firewall.extraCommands;
assert
  config.networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts
  == config.services.openssh.ports;
assert lib.elem config.services.tailscale.port config.networking.firewall.allowedUDPPorts;
assert !config.services.openssh.settings.PasswordAuthentication;
assert !config.services.openssh.settings.KbdInteractiveAuthentication;
assert !config.services.openssh.settings.X11Forwarding;
assert config.services.openssh.settings.PermitRootLogin == "no";
assert lib.all (setting: config.services.logind.settings.Login.${setting} == "ignore") [
  "HandleLidSwitch"
  "HandleLidSwitchExternalPower"
  "HandleLidSwitchDocked"
];
assert config.systemd.enableEmergencyMode;
assert config.services.logrotate.enable;
assert !(config ? home-manager);
assert
  !lib.any (enabled: enabled) [
    config.services.xserver.enable
    config.services.displayManager.enable
    config.programs.steam.enable
    config.services.flatpak.enable
    config.services.pipewire.enable
    config.hardware.bluetooth.enable
    config.virtualisation.docker.enable
  ];
config.system.build.toplevel
