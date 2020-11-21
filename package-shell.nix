{ nixpkgs ? import <nixpkgs> {}, compiler ? "default", doBenchmark ? false }:

let

  inherit (nixpkgs) pkgs;

  f = { mkDerivation, base, hpack, mtl, stdenv, transformers
      , unexceptionalio, unexceptionalio-trans
      }:
      mkDerivation {
        pname = "zio";
        version = "0.1.0.2";
        src = ./.;
        libraryHaskellDepends = [
          base mtl transformers unexceptionalio unexceptionalio-trans
        ];
        libraryToolDepends = [ hpack ];
        testHaskellDepends = [
          base mtl transformers unexceptionalio unexceptionalio-trans
        ];
        prePatch = "hpack";
        homepage = "https://github.com/bbarker/haskell-zio#readme";
        description = "App-centric Monad-transformer based on Scala ZIO (UIO + ReaderT + ExceptT)";
        license = stdenv.lib.licenses.mpl20;
      };

  haskellPackages = if compiler == "default"
                       then pkgs.haskellPackages
                       else pkgs.haskell.packages.${compiler};

  variant = if doBenchmark then pkgs.haskell.lib.doBenchmark else pkgs.lib.id;

  drv = variant (haskellPackages.callPackage f {});

in

  if pkgs.lib.inNixShell then drv.env else drv
