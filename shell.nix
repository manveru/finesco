with import ./nix/nixpkgs.nix;
pkgs.mkShell {
  buildInputs = [ cacert haskellEnv sass cabal2nix image_optim yarn yarn2nix ];

  LOCALE_ARCHIVE = "${buildPackages.glibcLocales}/lib/locale/locale-archive";
  LC_ALL = "en_US.UTF-8";

  shellHook = ''
    eval "$(grep ^export ${haskellEnv}/bin/ghc)"
    unset preHook # fix for lorri

    if [[ -d node_modules || -L node_modules ]]; then
      rm -rf node_modules
    fi

    ln -s "${finescoYarnPackages}/node_modules" node_modules
  '';
}
