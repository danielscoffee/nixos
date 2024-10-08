{
  # Enable networking
  networking.networkmanager.enable = true;

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
