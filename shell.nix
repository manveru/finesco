with import ./nix/nixpkgs.nix;
pkgs.mkShell {
  buildInputs = [ cacert sass image_optim yarn yarn2nix infuse
  rubyEnv.wrappedRuby
  watchexec
  ];

  LOCALE_ARCHIVE = "${buildPackages.glibcLocales}/lib/locale/locale-archive";
  LC_ALL = "en_US.UTF-8";

  shellHook = ''
    unset preHook # fix for lorri

    export PATH=$PATH:${finescoYarnPackages + "/node_modules/.bin"}
  '';

    # if [[ -d node_modules || -L node_modules ]]; then
    #   rm -rf node_modules
    # fi

    # ln -s "${finescoYarnPackages}/node_modules" node_modules
}
