{
  stdenv,
  lib,
  fetchurl,
}:

stdenv.mkDerivation rec {
  pname = "hello-fhs";
  version = "1.0.0";

  src = fetchurl {
    url = "https://example.com/hello.tar.gz";
    sha256 = "sha256-0000000000000000000000000000000000000000000000000000000000000000";
  };

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