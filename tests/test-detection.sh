#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DETECTION="$SCRIPT_DIR/../forge/core/detection.sh"
PASS=0
FAIL=0

assert_detected() {
  local pack="$1" dir="$2"
  local output
  output=$("$DETECTION" "$dir" 2>/dev/null) || {
    echo "  FAIL: detection.sh exited non-zero for $dir"
    FAIL=$((FAIL + 1))
    return
  }
  if echo "$output" | grep -q "\"$pack\""; then
    echo "  PASS: $pack detected in $dir"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $pack NOT detected in $dir"
    FAIL=$((FAIL + 1))
  fi
}

assert_not_detected() {
  local pack="$1" dir="$2"
  local output
  output=$("$DETECTION" "$dir" 2>/dev/null) || {
    echo "  FAIL: detection.sh exited non-zero for $dir"
    FAIL=$((FAIL + 1))
    return
  }
  if echo "$output" | grep -q "\"$pack\""; then
    echo "  FAIL: $pack should NOT be detected in $dir"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: $pack correctly not detected in $dir"
    PASS=$((PASS + 1))
  fi
}

FIXTURES="$SCRIPT_DIR/fixtures"
trap 'rm -rf "$FIXTURES"' EXIT
rm -rf "$FIXTURES"

# Fixture: nextjs project
mkdir -p "$FIXTURES/nextjs-project/src/app"
echo '{}' > "$FIXTURES/nextjs-project/package.json"
touch "$FIXTURES/nextjs-project/next.config.ts"

# Fixture: golang project
mkdir -p "$FIXTURES/go-project"
echo 'module example.com/test' > "$FIXTURES/go-project/go.mod"

# Fixture: python project
mkdir -p "$FIXTURES/python-project"
echo '[project]' > "$FIXTURES/python-project/pyproject.toml"

# Fixture: empty project
mkdir -p "$FIXTURES/empty-project"

# Fixture: project with forge.yaml overrides
mkdir -p "$FIXTURES/override-project/.forge"
echo '{}' > "$FIXTURES/override-project/package.json"
touch "$FIXTURES/override-project/next.config.mjs"
cat > "$FIXTURES/override-project/.forge/forge.yaml" << 'YAML'
extra_packs:
  - healthcare
suppress_packs:
  - docker
YAML
touch "$FIXTURES/override-project/Dockerfile"

# Fixture: full-suppression project (all detected packs suppressed — tests FILTERED[@] empty-array edge case)
mkdir -p "$FIXTURES/full-suppress-project/.forge"
echo 'module example.com/suppress' > "$FIXTURES/full-suppress-project/go.mod"
cat > "$FIXTURES/full-suppress-project/.forge/forge.yaml" << 'YAML'
suppress_packs:
  - golang
YAML

echo "=== Detection Engine Tests ==="

echo ""
echo "--- Next.js project ---"
assert_detected "nextjs" "$FIXTURES/nextjs-project"
assert_not_detected "golang" "$FIXTURES/nextjs-project"
assert_not_detected "python" "$FIXTURES/nextjs-project"

echo ""
echo "--- Go project ---"
assert_detected "golang" "$FIXTURES/go-project"
assert_not_detected "nextjs" "$FIXTURES/go-project"

echo ""
echo "--- Python project ---"
assert_detected "python" "$FIXTURES/python-project"
assert_not_detected "golang" "$FIXTURES/python-project"

echo ""
echo "--- Empty project ---"
assert_not_detected "nextjs" "$FIXTURES/empty-project"
assert_not_detected "golang" "$FIXTURES/empty-project"
assert_not_detected "python" "$FIXTURES/empty-project"

echo ""
echo "--- Override project ---"
assert_detected "nextjs" "$FIXTURES/override-project"
assert_detected "healthcare" "$FIXTURES/override-project"
assert_not_detected "docker" "$FIXTURES/override-project"

echo ""
echo "--- Full-suppression project (all detected packs suppressed) ---"
assert_not_detected "golang" "$FIXTURES/full-suppress-project"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] || exit 1
