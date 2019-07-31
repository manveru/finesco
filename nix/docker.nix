{ pkgs ? import ./nixpkgs.nix }:
let
  ghc = pkgs.haskell.packages.ghc865.ghcWithPackages
    (ps: with ps; [ hakyll hakyll-favicon ]);

  site = pkgs.stdenv.mkDerivation {
    name = "finesco-hakyll";
    src = ../site.hs;
    nativeBuildInputs = [ ghc ];
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
in pkgs.dockerTools.buildLayeredImage {
  name = "registry.gitlab.com/manveru/finesco";
  tag = "latest";
  created = "now";
  maxLayers = 110;

  config = {
    Env = pkgs.lib.mapAttrsFlatten (k: v: "${k}=${v}") {
      PATH = "${site}/bin:${pkgs.finescoYarnPackages}/node_modules/.bin:${pkgs.bashInteractive}/bin";
      LOCALE_ARCHIVE =
        "${pkgs.buildPackages.glibcLocales}/lib/locale/locale-archive";
      LC_ALL = "en_US.UTF-8";
    };
  };
}
