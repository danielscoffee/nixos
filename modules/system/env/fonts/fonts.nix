{ pkgs, ... }:
let
  rofiFeather =
    pkgs.runCommand "rofi-feather"
      {
        src = pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/adi1090x/rofi/512a585fff6da5b2a90e5948059b062516ddb2e7/fonts/Icomoon-Feather.ttf";
          hash = "sha256-kKyBYq8r6+aL/vLWLgVqgTFjPWzGhYdqsMgmQhOBAVg=";
        };
      }
      ''
        install -Dm644 "$src" "$out/share/fonts/truetype/Icomoon-Feather.ttf"
      '';
in
{
  fonts.packages = with pkgs; [
    rofiFeather
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
  ];
}
