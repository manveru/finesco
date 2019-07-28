{ mkDerivation, base, hakyll, hakyll-favicon, regex-pcre-builtin
, stdenv
}:
mkDerivation {
  pname = "finesco";
  version = "0.1.0.0";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [
    base hakyll hakyll-favicon regex-pcre-builtin
  ];
  license = "unknown";
  hydraPlatforms = stdenv.lib.platforms.none;
}
