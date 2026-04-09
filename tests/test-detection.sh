#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DETECTION="$SCRIPT_DIR/../forge/core/detection.sh"
PASS=0
FAIL=0

assert_detected() {
  local pack="$1" dir="$2"
  if "$DETECTION" "$dir" 2>/dev/null | grep -q "\"$pack\""; then
    echo "  PASS: $pack detected in $dir"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $pack NOT detected in $dir"
    FAIL=$((FAIL + 1))
  fi
}

assert_not_detected() {
  local pack="$1" dir="$2"
  if "$DETECTION" "$dir" 2>/dev/null | grep -q "\"$pack\""; then
    echo "  FAIL: $pack should NOT be detected in $dir"
    FAIL=$((FAIL + 1))
  else
    echo "  PASS: $pack correctly not detected in $dir"
    PASS=$((PASS + 1))
  fi
}

FIXTURES="$SCRIPT_DIR/fixtures"
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

rm -rf "$FIXTURES"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] || exit 1
