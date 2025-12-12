# Simple check that only validates GitHub URLs in templates
{ pkgs, lib, ... }:

pkgs.runCommand "templates-github-check" {
  nativeBuildInputs = [ pkgs.python3 ];
} ''
  set -e
  echo "🔍 Checking GitHub URLs in templates..."

  # Simple Python script to check GitHub URLs
  python3 <<'EOF'
import os
import re
from pathlib import Path

EXPECTED_GITHUB_URL = "github:luochen1990/flake-fhs"
templates_dir = Path("${../templates}")

if not templates_dir.exists():
    print(f"❌ Templates directory not found: {templates_dir}")
    exit(1)

all_passed = True
for template_dir in templates_dir.iterdir():
    if not template_dir.is_dir() or template_dir.name.startswith('.'):
        continue

    flake_nix = template_dir / "flake.nix"
    if not flake_nix.exists():
        print(f"❌ {template_dir.name}: flake.nix not found")
        all_passed = False
        continue

    with open(flake_nix, 'r') as f:
        content = f.read()

    if EXPECTED_GITHUB_URL in content:
        print(f"✅ {template_dir.name}: Uses correct GitHub URL")
    else:
        print(f"❌ {template_dir.name}: Does not use expected GitHub URL: {EXPECTED_GITHUB_URL}")
        all_passed = False

if all_passed:
    print("✅ All templates use correct GitHub URL!")
    exit(0)
else:
    print("❌ Some templates have incorrect GitHub URLs")
    exit(1)
EOF

  echo "✅ GitHub URL check completed!"
  touch $out
''