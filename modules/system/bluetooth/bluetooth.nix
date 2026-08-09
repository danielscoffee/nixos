{
  # Enable networking
  networking.networkmanager.enable = true;
  networking.networkmanager.insertNameservers = [
    "1.1.1.1"
    "1.0.0.1"
  ];

  # Enable Bluetooth
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;
  hardware.bluetooth.enable = true;
  hardware.bluetooth.settings = {
    General = {
      Experimental = true;
    };
  };
}
