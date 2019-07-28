{ pkgs ? import ./nix/nixpkgs.nix }:
let
  finesco = pkgs.haskell.packages.ghc865.callPackage ./finesco.nix { };
in pkgs.haskell.lib.justStaticExecutables finesco
