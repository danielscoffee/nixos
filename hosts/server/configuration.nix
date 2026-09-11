{ lib, ... }:
{
  imports = [
    ../../modules/server
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

  users.users.daniel = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    # Provision your public key before relying on SSH access.
    openssh.authorizedKeys.keyFiles = lib.optional (builtins.pathExists ./admin.pub) ./admin.pub;
  };

  system.stateVersion = "24.05";
}
