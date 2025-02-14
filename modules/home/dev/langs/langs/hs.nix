{ pkgs, ... }: {
  home.packages = with pkgs.haskellPackages; [
    ghc
    cabal-install
    haskell-language-server
  ];
}
