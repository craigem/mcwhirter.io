{ nixpkgs ? import <nixpkgs> {}, compiler ? "default"}:
let
  inherit (nixpkgs) pkgs;
  haskellPackages = if compiler == "default"
                       then pkgs.haskellPackages
                       else pkgs.haskell.packages.${compiler};
  mcwhirter-io = haskellPackages.callPackage ./mcwhirter-io.nix {};
in
nixpkgs.stdenv.mkDerivation {
  name = "mcwhirter-io-website";
  buildInputs = [ mcwhirter-io ];
  src = ./.;
  buildPhase = ''
    echo "Setting LC_ALL to C.UTF-8 to avoid invalid byte sequence."
    export LC_ALL=C.UTF-8
    site build
  '';
  installPhase = ''
    mkdir $out
    cp -R _site/* $out
  '';
}
