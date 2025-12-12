# Test that validates all templates using Python validation
#
# IMPORTANT: This test MUST use local path replacement to validate templates work with the
# current development version of flake-fhs, NOT the GitHub release. We copy the flake-fhs
# source to a local directory within the Nix build environment and test templates against it.
# This ensures we validate the actual logic being developed.
#
# Do NOT modify this to use GitHub URLs or skip local path testing, as that would defeat
# the purpose of validating the current development changes.
{ pkgs, lib, ... }:

# Use builtins.path with filter to ensure we get current source with all changes
let
  currentSource = builtins.path {
    path = toString ../../.;
    # Include all files to capture current changes
    filter = path: type: true;
  };
in
pkgs.runCommand "templates-validation"
  {
    nativeBuildInputs = [
      pkgs.python3
      pkgs.nix
    ];
  }
  ''
    set -e
    echo "🧪 Running comprehensive template validation..."

    # Copy current source (includes all uncommitted changes)
    cp -r ${currentSource} ./source
    chmod -R u+rw ./source

    # Run Python validator with current source
    python3 ${./validators.py} \
      --templates-dir ./source/templates \
      --project-root ./source \
      --format text

    echo "✅ Template validation completed!"
    touch $out
  ''
