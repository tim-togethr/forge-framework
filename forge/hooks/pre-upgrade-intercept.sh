#!/usr/bin/env bash
set -euo pipefail

# Forge PreToolUse Hook — Intercepts /forge upgrade
# Runs upgrade.sh directly so Claude cannot improvise.
# For non-upgrade Skill calls, exits 0 (allow) immediately.

INPUT=$(cat)

# Extract skill name — no jq, manual parsing
SKILL=$(echo "$INPUT" | grep -o '"skill"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 \
  | sed 's/.*"skill"[[:space:]]*:[[:space:]]*"//;s/".*//' || true)

# Only intercept upgrade calls
case "${SKILL:-}" in
  *upgrade*) ;;
  *) exit 0 ;;
esac

# --- Run the upgrade script ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPGRADE_SCRIPT="$SCRIPT_DIR/scripts/upgrade.sh"

if [ ! -f "$UPGRADE_SCRIPT" ]; then
  ESCAPED="Upgrade script not found at $UPGRADE_SCRIPT. Reinstall Forge."
else
  # Check for --check flag
  ARGS=$(echo "$INPUT" | grep -o '"args"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 \
    | sed 's/.*"args"[[:space:]]*:[[:space:]]*"//;s/".*//' 2>/dev/null || true)

  if [[ "${ARGS:-}" == *--check* ]]; then
    OUTPUT=$(bash "$UPGRADE_SCRIPT" --check 2>&1) || true
  else
    OUTPUT=$(bash "$UPGRADE_SCRIPT" 2>&1) || true
  fi

  # Escape for JSON — backslashes, quotes, tabs, newlines
  ESCAPED=$(printf '%s' "$OUTPUT" | awk '{
    gsub(/\\/, "\\\\")
    gsub(/"/, "\\\"")
    gsub(/\t/, "\\t")
    gsub(/\r/, "")
    if (NR > 1) printf "\\n"
    printf "%s", $0
  }')
fi

# Block the skill call — return script output as the reason
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$ESCAPED"
