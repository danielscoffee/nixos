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
  home = config.home-manager.users.daniel;
  homePackages = map toString home.home.packages;
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
assert config ? home-manager;
assert config.programs.fish.enable;
assert config.users.users.daniel.shell.outPath == config.programs.fish.package.outPath;
assert config.home-manager.useUserPackages;
assert config.home-manager.backupFileExtension == "hm-backup";
assert !config.home-manager.overwriteBackup;
assert lib.all (name: home.programs.${name}.enable) [
  "fish"
  "neovim"
  "tmux"
  "fzf"
  "starship"
  "zoxide"
];
assert home.programs.neovim.defaultEditor;
assert home.programs.neovim.viAlias && home.programs.neovim.vimAlias;
assert home.programs.tmux.prefix == "M-s";
assert lib.all (name: home.xdg.configFile.${name}.enable) [
  "fish/config.fish"
  "nvim/init.lua"
  "tmux/tmux.conf"
];
assert lib.hasInfix (builtins.readFile ../dotfiles/server/nvim/init.lua)
  home.programs.neovim.initLua;
assert lib.all (package: lib.elem (toString package) homePackages) (
  with server.pkgs;
  [
    gh
    gcc
    cmake
    pkg-config
    python3
    nodejs
    go
    ripgrep
    fd
    jq
    unzip
    zip
    nixfmt
    nixd
    sesh
  ]
);
assert !home.gtk.enable && !home.qt.enable;
assert !home.programs.kitty.enable && !home.programs.vscode.enable;
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
