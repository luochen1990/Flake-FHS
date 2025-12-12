{ self, pkgs, lib, ... }:

pkgs.runCommand "templates-validation"
  {
    src = self;
    nativeBuildInputs = [
      pkgs.python3
      pkgs.nix
    ];
  }
  ''
    set -e
    echo "🧪 Running comprehensive template validation..."

    # Run Python validator with current source
    python3 ${./validators.py} --project-root $src --templates-dir $src/templates --format text > $out
  ''
