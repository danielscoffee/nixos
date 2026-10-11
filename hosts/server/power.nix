{ config, ... }:
let
  # CPU package power caps. Firmware ships 28 W sustained / 64 W burst, sized for
  # a laptop used in bursts, not one under load 24/7 in a thin chassis.
  sustainedWatts = 15;
  burstWatts = 25;
  microwatts = watts: toString (watts * 1000000);
in
{
  # Acer battery health mode: stop charging at 80%. The pack sits on AC forever.
  boot.extraModulePackages = [ config.boot.kernelPackages.acer-wmi-battery ];
  boot.kernelModules = [
    "acer-wmi-battery"
    # Exposes the SATA SSD temperature to hwmon (btop, smartd).
    "drivetemp"
  ];
  boot.extraModprobeConfig = "options acer_wmi_battery enable_health_mode=1";

  # Turn the always-on panel off after 60s without console input.
  boot.kernelParams = [ "consoleblank=60" ];

  # udev, not tmpfiles: intel_rapl_msr is a module and may load after tmpfiles runs.
  services.udev.extraRules = ''
    ACTION!="remove", SUBSYSTEM=="powercap", KERNEL=="intel-rapl:0", ATTR{constraint_0_power_limit_uw}="${microwatts sustainedWatts}", ATTR{constraint_1_power_limit_uw}="${microwatts burstWatts}"
    ACTION!="remove", SUBSYSTEM=="cpu", KERNEL=="cpu[0-9]*", ATTR{cpufreq/energy_performance_preference}="balance_power"
  '';

  # Log disk temps at 55°C, warn at 65°C; weekly short self-test (Sun 03:00).
  services.smartd = {
    enable = true;
    defaults.autodetected = "-a -W 0,55,65 -s S/../../7/03";
  };
}
