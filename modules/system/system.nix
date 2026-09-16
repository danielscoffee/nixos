{
  imports = [
    ./env/steam.nix
    ./bluetooth/bluetooth.nix
    ./hardware/controllers.nix
    ./env/fonts/fonts.nix
    ./env/i3.nix
  ];

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };
}
