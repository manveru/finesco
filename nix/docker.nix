{ pkgs ? import ./nixpkgs.nix }:
let
  site = pkgs.symlinkJoin {
    name = "finesco-files";
    paths = [
      ../admin
      ../blog
      ../images
      ../info
      ../js
      ../nix
      ../scripts
      ../scss
      ../templates
      ../default.nix
      ../Gemfile
      ../Gemfile.lock
      ../gemset.nix
    ];
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
