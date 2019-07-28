{ pkgs ? import ./nixpkgs.nix, default ? import ./. }:
let
  ghc = pkgs.haskell.packages.ghc865.ghcWithPackages (ps: with ps; [ hakyll ]);
  site = pkgs.stdenv.mkDerivation {
    name = "finesco-hakyll";
    src = ../site.hs;
    nativeBuildInputs = [ ghc pkgs.file ];
    unpackPhase = "true";
    buildPhase = ''
      cp $src site.hs
      ghc --make site.hs
    '';
    installPhase = ''
      mkdir -p $out/bin
      mv site $out/bin
    '';
  };
in
pkgs.dockerTools.buildLayeredImage {
  name = "hakyll";
  maxLayers = 100;
  contents = [
    site
  ];
}
