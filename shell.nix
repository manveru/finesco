let
  pkgs = import ./nix/nixpkgs.nix;
  ghc = pkgs.haskell.packages.ghc865.ghcWithPackages (ps: with ps; [ hakyll hakyll-favicon ]);
in pkgs.mkShell {
  buildInputs = [ ghc pkgs.locale pkgs.sass pkgs.cabal2nix pkgs.image_optim ];
  LOCALE_ARCHIVE = "${pkgs.buildPackages.glibcLocales}/lib/locale/locale-archive";

  LC_ALL = "en_US.UTF-8";
  shellHook = ''
    eval "$(grep ^export ${ghc}/bin/ghc)"
    unset preHook
  '';
}
