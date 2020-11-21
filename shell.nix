let
  pkgShell = (import ./package-shell.nix);
  # 20.09 on 11/20/2020
  pkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/58f9c4c7d3a42c912362ca68577162e38ea8edfb.tar.gz") {};
  in pkgShell {nixpkgs = pkgs;}
