{ pkgs ? import ./nixpkgs.nix, default ? import ./. }:
let
  ghc = pkgs.haskell.packages.ghc865.ghcWithPackages (ps: with ps; [ hakyll ]);
in
pkgs.dockerTools.buildLayeredImage {
  name = "hakyll";
  maxLayers = 100;
  contents = [
    pkgs.ncdu
    pkgs.vim
    pkgs.bashInteractive
    ghc
  ];
}
