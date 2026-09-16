{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../modules/server
    inputs.home-manager.nixosModules.home-manager
  ]
  ++ lib.optional (builtins.pathExists ./hardware-configuration.nix) ./hardware-configuration.nix;

  # Generate hardware-configuration.nix on this laptop before building.
  # No fallback filesystem or borrowed disk UUIDs.
  networking.hostName = "server";
  # Allow LAN IPv4 SSH without opening port 22 globally. Adjust for a different LAN.
  networking.firewall.extraCommands = ''
    iptables -w -A nixos-fw -s 192.168.100.0/24 -p tcp --dport 22 -j nixos-fw-accept
  '';

  boot.loader = {
    systemd-boot.enable = lib.mkDefault true;
    efi.canTouchEfiVariables = lib.mkDefault true;
  };

  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "br-abnt2";

  programs.fish.enable = true;

  users.users.daniel = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    # Provision your public key before relying on SSH access.
    openssh.authorizedKeys.keyFiles = lib.optional (builtins.pathExists ./admin.pub) ./admin.pub;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    users.daniel = import ../../modules/home/server.nix;
  };

  system.stateVersion = "24.05";
}
