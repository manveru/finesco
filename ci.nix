let
  pkgs = import ./nix/nixpkgs.nix;
in pkgs.recurseIntoAttrs {
  site = import ./default.nix {};
}
