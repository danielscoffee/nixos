{ pkgs, ... }:
{
  imports = [
    ./apps/obs.nix
    ./apps/dunst.nix
  ];

  xdg.configFile."television" = {
    source = ../../../dotfiles/television;
    recursive = true;
  };

  xdg.configFile."flameshot/flameshot.ini" = {
    force = true;
    text = ''
      [General]
      useX11LegacyScreenshot=true
    '';
  };

  home.packages = with pkgs; [
    proton-vpn
    stoat-desktop
    mangohud
    firefox
    jetbrains-toolbox
    unzip
    television
    anki
    flatpak
    (gearlever.override {
      # Backport https://github.com/NixOS/nixpkgs/pull/549694.
      dwarfs = dwarfs.overrideAttrs (oldAttrs: {
        version = "0.15.6";
        src = pkgs.fetchFromGitHub {
          owner = "mhx";
          repo = "dwarfs";
          tag = "v0.15.6";
          fetchSubmodules = true;
          hash = "sha256-Nq7H/qm58j77YmYmlkEhU8Hfh59Z2+Vj+4apn31HHHc=";
        };
        env = oldAttrs.env // {
          GTEST_FILTER = "-${
            builtins.concatStringsSep ":" [
              "dwarfs/tools_test.end_to_end/*"
              "dwarfs/tools_test.mutating_and_error_ops/*"
              "dwarfs/tools_test.categorize/*"
              "dwarfs/fuse_driver_test*"
              "tools_test.dwarfs_obsolete_options*"
              "sparse_files_test.random_large_files*"
              "sparse_files_test.random_small_files_fuse*"
              "sparse_files_test.huge_holes_fuse*"
              "xattr_test.portable_xattr"
            ]
          }";
        };
      });
    })

    shotcut
    btop
    brightnessctl
    obsidian
    # BUG: ELECTRON EOL
    # bitwarden-desktop
    discord
    flameshot
    droidcam
    spotify
    pavucontrol
  ];
}
