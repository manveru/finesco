let
  pkgs = import ./nix/nixpkgs.nix;
  ghc = pkgs.haskell.packages.ghc865.ghcWithPackages (ps: with ps; [ hakyll ]);
in pkgs.mkShell {
  buildInputs = [ ghc ];
  shellHook = ''
    eval $(grep ^export ${ghc}/bin/ghc)"
    unset preHook
  '';
}
