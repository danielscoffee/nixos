{
  description = "OpenAI Codex CLI from official release binaries";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = builtins.attrNames (nixpkgs.lib.importJSON ./sources.json).platforms;
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        codex = pkgs.callPackage ./package.nix { };
        default = codex;
      });

      overlays.default = final: _prev: {
        codex = final.callPackage ./package.nix { };
      };
    };
}
