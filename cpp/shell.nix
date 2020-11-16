{ pkgs   ? import <nixpkgs> {},
  stdenv ? pkgs.stdenv,
  jemalloc ? pkgs.jemalloc
#  jemalloc ? pkgs.jemalloc450
}:

with import <nixpkgs> {}; {
  qpidEnv = stdenvNoCC.mkDerivation {
    name = "my-gcc7-environment";
    buildInputs = [
      gcc
      jemalloc
    ];
  };
}
