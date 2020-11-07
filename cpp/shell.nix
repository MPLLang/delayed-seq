with import <nixpkgs> {}; {
  qpidEnv = stdenvNoCC.mkDerivation {
    name = "my-gcc7-environment";
    buildInputs = [
        gcc7
    ];
  };
}
