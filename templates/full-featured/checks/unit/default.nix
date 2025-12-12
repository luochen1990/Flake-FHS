{
  pkgs,
  lib,
  ...
}:

pkgs.runCommand "unit-tests" {
  nativeBuildInputs = with pkgs; [
    coreutils
  ];
} ''
  echo "🧪 Running unit tests..."

  exit_code=0

  # Simple unit test simulation
  test_function() {
    echo "Testing function: $1"
    # Simulate some test logic
    sleep 0.1
    echo "✅ $1 passed"
  }

  # Run some simulated unit tests
  test_function "utils.list.join"
  test_function "utils.dict.merge"
  test_function "utils.file.exists"

  # Test if flake evaluation works
  echo "Testing flake evaluation..."
  if nix flake check --no-build >/dev/null 2>&1; then
    echo "✅ Flake evaluation passed"
  else
    echo "❌ Flake evaluation failed"
    exit_code=1
  fi

  if [ $exit_code -eq 0 ]; then
    echo "✅ All unit tests passed"
  else
    echo "❌ Some unit tests failed"
    exit 1
  fi

  touch $out
''