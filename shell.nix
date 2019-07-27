let
  pkgs = import ./nix/nixpkgs.nix;
  hsPkgs = import ./nix/default.nix;
  haskell-nix = import ./nix/haskell.nix { inherit pkgs; };

  haskellDevPkgs = with pkgs.haskell.packages.ghc865; [
    haskell-nix.nix-tools
    cabal-install
    ghcid
    stylish-haskell
    brittany
  ];

  devPkgs = with pkgs; [ ruby_2_6 watchexec entr sass cacert ];
in hsPkgs.shellFor {
  packages = ps: with ps; [ finesco ];
  withHoogle = true;

  buildInputs = devPkgs ++ haskellDevPkgs;

  shellHook = ''
    unset preHook
  '';
}
