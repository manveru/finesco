let
  pkgs = import ./nix/nixpkgs.nix;
  ghc = pkgs.haskell.packages.ghc865.ghcWithPackages (ps: with ps; [ hakyll ]);
in pkgs.mkShell {
  buildInputs = [ ghc pkgs.locale pkgs.sass ];
  LOCALE_ARCHIVE = "${pkgs.buildPackages.glibcLocales}/lib/locale/locale-archive";

  LC_ALL = "en_US.UTF-8";
  shellHook = ''
    eval $(grep ^export ${ghc}/bin/ghc)"
    unset preHook
  '';
}
