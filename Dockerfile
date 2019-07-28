FROM lnl7/nix:2019-03-01
RUN nix-env -iA nixpkgs.gzip nixpkgs.gnutar nixpkgs.curl
COPY shell.nix .
COPY nix/nixpkgs.nix nix/nixpkgs.nix
RUN nix-shell --run 'echo done'
