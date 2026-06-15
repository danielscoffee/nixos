{ inputs, pkgs, ... }:
{
  imports = [
    inputs.nixos-wsl.nixosModules.default
    inputs.home-manager.nixosModules.home-manager
    ../../modules/nix-ld.nix
  ];

  wsl = {
    enable = true;
    defaultUser = "daniel";
    startMenuLaunchers = true;

    interop.register = true;

    wslConf = {
      network.hostname = "nixos-wsl";
      interop = {
        enabled = true;
        appendWindowsPath = false;
      };
    };
  };

  networking.hostName = "nixos-wsl";
  networking.firewall.enable = false;

  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "en_US.UTF-8";
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

  users.users.daniel = {
    isNormalUser = true;
    shell = pkgs.fish;
    description = "daniel";
    extraGroups = [ "wheel" ];
  };

  programs.fish.enable = true;
  programs.zsh.enable = true;

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    backupFileExtension = "hm-backup";
    users.daniel = import ../../modules/home/wsl.nix;
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    vim
    neovim
    ripgrep
    fd
    jq
    unzip
    zip
    gnumake
    gcc
    openssh
  ];

  system.stateVersion = "24.05";
}
