{ inputs, pkgs, ... }:

{
  imports = [ ./modules.nix ];
  #LidSwitch ignore
  services.logind.lidSwitch = "ignore";

  networking.hostName = "coffee";
  networking.firewall.enable = false;

  # Set your time zone.
  time.timeZone = "America/Sao_Paulo";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.inputMethod.enabled = "ibus";
  i18n.inputMethod.ibus.engines = with pkgs.ibus-engines; [ libpinyin ];

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "br";
    variant = "thinkpad";
  };

  # Configure console keymap
  console.keyMap = "br-abnt2";

  # Home-manager setup
  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = { "daniel" = import ../../modules/home/home.nix; };
  };

  # Flaking
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
  ];

  # System Version
  system.stateVersion = "24.05";

}
