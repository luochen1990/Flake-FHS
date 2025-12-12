# Test that validates all templates using Python validation
{ pkgs, lib, ... }:

pkgs.runCommand "templates-validation" {
  nativeBuildInputs = [ pkgs.python3 pkgs.nix ];
} ''
  set -e
  echo "🧪 Running comprehensive template validation..."

  # Create a temp directory with proper permissions
  export TMPDIR=$(mktemp -d)
  chmod 755 "$TMPDIR"

  # Run Python validator
  python3 ${../templates-validators.py} \
    --templates-dir ${../templates} \
    --project-root ${../.} \
    --format text

  echo "✅ Template validation completed!"
  touch $out
''