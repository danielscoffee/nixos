{ pkgs, ... }:
{
  imports = [
    ./ai/codex.nix
    ./ai/claude-code.nix
    ./ai/pi.nix
  ];

  nixpkgs.overlays = [
    (_: prev: {
      rtk = prev.rtk.overrideAttrs {
        # Rust 1.97 exposes dead code in rtk 0.43.0 test builds.
        # Remove after nixos-unstable includes nixpkgs 2f08d991.
        env.RUSTFLAGS = "--cap-lints warn";
      };
    })
  ];

  home.packages = with pkgs; [
    rtk
  ];
}
