#!/usr/bin/env bash
# Validates a Forge pack directory has correct structure and format.
# Usage: validate-pack.sh /path/to/pack
set -euo pipefail

PACK_DIR="$1"
PACK_NAME=$(basename "$PACK_DIR")
ERRORS=0

check() {
  if [ ! "$1" "$2" ]; then
    echo "  FAIL: $3"
    ERRORS=$((ERRORS + 1))
  else
    echo "  OK: $3"
  fi
}

echo "=== Validating pack: $PACK_NAME ==="

# pack.yaml exists and has required fields
check -f "$PACK_DIR/pack.yaml" "pack.yaml exists"

if [ -f "$PACK_DIR/pack.yaml" ]; then
  for field in "name:" "detect:" "roles:"; do
    if grep -q "^$field" "$PACK_DIR/pack.yaml" 2>/dev/null; then
      echo "  OK: pack.yaml has $field"
    else
      if [ "$field" = "detect:" ]; then
        echo "  SKIP: pack.yaml missing $field (opt-in pack)"
      else
        echo "  FAIL: pack.yaml missing $field"
        ERRORS=$((ERRORS + 1))
      fi
    fi
  done
fi

# skills/ directory exists and has at least one skill
check -d "$PACK_DIR/skills" "skills/ directory exists"

if [ -d "$PACK_DIR/skills" ]; then
  SKILL_COUNT=$(find "$PACK_DIR/skills" -name "SKILL.md" | wc -l | tr -d ' ')
  if [ "$SKILL_COUNT" -gt 0 ]; then
    echo "  OK: $SKILL_COUNT skills found"
  else
    echo "  FAIL: no SKILL.md files in skills/"
    ERRORS=$((ERRORS + 1))
  fi

  for skill_file in $(find "$PACK_DIR/skills" -name "SKILL.md"); do
    skill_name=$(basename "$(dirname "$skill_file")")
    if head -5 "$skill_file" | grep -q "^name:"; then
      echo "  OK: $skill_name has name field"
    else
      echo "  FAIL: $skill_name missing name field"
      ERRORS=$((ERRORS + 1))
    fi
    if head -10 "$skill_file" | grep -q "^description:"; then
      echo "  OK: $skill_name has description field"
    else
      echo "  FAIL: $skill_name missing description field"
      ERRORS=$((ERRORS + 1))
    fi
  done
fi

echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "=== PASS: $PACK_NAME is valid ==="
else
  echo "=== FAIL: $PACK_NAME has $ERRORS errors ==="
  exit 1
fi
