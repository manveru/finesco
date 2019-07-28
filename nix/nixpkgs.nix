import (fetchTarball {
  url =
    "https://github.com/nixos/nixpkgs-channels/archive/a835adc10cb813d214a9069361d94a2a3f8eb3a5.tar.gz";
  sha256 = "0q2nqxadlhs52q02lis27qgx624gbz9p809a5iw6a3fpbnawjdm9";
}) { config = { allowUnfree = true; }; }
