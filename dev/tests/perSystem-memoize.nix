# Test that perSystem evaluation is memoized: calling withSystem twice for the
# same undeclared system should only evaluate perSystem once.
# Run with:
#   nix build .#checks.x86_64-linux.perSystem-memoize

{ flake-parts, runCommand, nix }:
runCommand "perSystem-memoize" { nativeBuildInputs = [ nix ]; } ''
  export HOME="$(realpath .)"
  unset NIX_STORE
  export NIX_STORE_DIR=${builtins.storeDir}
  export NIX_REMOTE="$HOME/storedata"

  nix eval \
    --extra-experimental-features 'nix-command flakes' \
    --no-write-lock-file \
    --offline \
    --substituters "" \
    --override-input flake-parts ${flake-parts} \
    --override-input flake-parts/nixpkgs-lib ${flake-parts.inputs.nixpkgs-lib} \
    "${./perSystem-memoize}#result" \
    2>eval-stderr

  count=$(grep -c "Evaluating perSystem for foo" eval-stderr || true)
  cat eval-stderr >&2
  echo "Trace count: $count"
  if [ "$count" -ne 1 ]; then
    echo "FAIL: expected perSystem to be evaluated exactly once, but it was evaluated $count times"
    exit 1
  fi
  echo "PASS: perSystem evaluated exactly once"
  touch $out
''
