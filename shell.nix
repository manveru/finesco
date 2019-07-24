let
  pkgs = import ./nix/nixpkgs.nix;
  hsPkgs = import ./nix/default.nix;
  haskell-nix = import ./nix/haskell.nix { inherit pkgs; };
  otherDeps = (haskell-nix.haskellPackages.ghcWithPackages
  (ps: with ps; [ cabal-install stylish-haskell brittany ]));
in hsPkgs.shellFor {
  packages = ps: with ps; [ finesco ];
  withHoogle = true;

  buildInputs = with pkgs; with haskell.packages.ghc865; [
    ruby_2_6
    watchexec
    entr
    sass
    cacert
    haskell-nix.nix-tools
    cabal-install
    ghcid
    stylish-haskell
    brittany
  ];
}
