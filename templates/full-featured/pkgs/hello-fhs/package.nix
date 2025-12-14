{
  stdenv,
  lib,
}:

stdenv.mkDerivation rec {
  pname = "hello-fhs";
  version = "1.0.0";

  # No src needed - we'll create the script directly
  buildInputs = [ ];

  phases = [ "installPhase" ];

  installPhase = ''
        mkdir -p $out/bin
        echo '#!/bin/sh
    echo "Hello from Flake FHS package ${pname}-${version}!"' > $out/bin/hello-fhs
        chmod +x $out/bin/hello-fhs
  '';

  meta = {
    description = "A simple hello package demonstrating Flake FHS";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
