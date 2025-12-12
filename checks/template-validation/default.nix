# Test that validates all templates using Python validation
#
# IMPORTANT: This test MUST use local path replacement to validate templates work with the
# current development version of flake-fhs, NOT the GitHub release. We copy the flake-fhs
# source to a local directory within the Nix build environment and test templates against it.
# This ensures we validate the actual logic being developed.
#
# Do NOT modify this to use GitHub URLs or skip local path testing, as that would defeat
# the purpose of validating the current development changes.
{ self, pkgs, lib, ... }:

# Use builtins.path with filter to ensure we get current source with all changes
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
    cd $src
    python3 ${./validators.py} --project-root . --templates-dir ./templates --format text
    touch $out
  ''
