{ system, compiler, flags, pkgs, hsPkgs, pkgconfPkgs, ... }:
  {
    flags = {};
    package = {
      specVersion = "1.10";
      identifier = { name = "finesco"; version = "0.1.0.0"; };
      license = "NONE";
      copyright = "";
      maintainer = "";
      author = "";
      homepage = "";
      url = "";
      synopsis = "";
      description = "";
      buildType = "Simple";
      };
    components = {
      exes = { "site" = { depends = [ (hsPkgs.base) (hsPkgs.hakyll) ]; }; };
      };
    } // rec { src = (pkgs.lib).mkDefault ../.; }