let
  haskell = import ./haskell.nix { };

  pkgSet = haskell.mkCabalProjectPkgSet {
    plan-pkgs = import ./pkgs.nix;
    pkg-def-extras = [ ];
    modules = [ ];
  };

in pkgSet.config.hsPkgs // { _config = pkgSet.config; }
