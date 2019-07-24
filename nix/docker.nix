{ pkgs ? import ./nixpkgs.nix, default ? import ./. }:
pkgs.dockerTools.buildLayeredImage {
  name = "finesco";
  maxLayers = 100;
  contents = [
    pkgs.ncdu
    pkgs.vim
    pkgs.bashInteractive
    default.finesco.components.exes.site
  ];
}
