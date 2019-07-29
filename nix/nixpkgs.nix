let
  nixpkgsSource = fetchTarball {
    url =
      "https://github.com/nixos/nixpkgs-channels/archive/a835adc10cb813d214a9069361d94a2a3f8eb3a5.tar.gz";
    sha256 = "0q2nqxadlhs52q02lis27qgx624gbz9p809a5iw6a3fpbnawjdm9";
  };

  yarn2nixSource = fetchTarball {
    url =
      "https://github.com/moretea/yarn2nix/archive/780e33a07fd821e09ab5b05223ddb4ca15ac663f.tar.gz";
    sha256 = "1f83cr9qgk95g3571ps644rvgfzv2i4i7532q8pg405s4q5ada3h";
  };

  yarn2nix = import yarn2nixSource { };

in import nixpkgsSource {
  config = { allowUnfree = true; };
  overlays = [
    (self: super: {
      inherit (yarn2nix) yarn2nix mkYarnModules;

      haskellEnv = super.haskell.packages.ghc865.ghcWithPackages
        (ps: with ps; [ hakyll hakyll-favicon ]);

      finescoYarnPackages = yarn2nix.mkYarnModules {
        name = "finesco";
        pname = "finesco";
        version = "1.0";
        packageJSON = ../package.json;
        yarnLock = ../yarn.lock;
        yarnNix = ../yarn.nix;
      };
    })
  ];
}
