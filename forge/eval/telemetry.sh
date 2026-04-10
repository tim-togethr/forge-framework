#!/usr/bin/env bash
# Forge Telemetry — appends skill usage data to .forge/eval/usage.jsonl
# Called with: telemetry.sh <skill> <outcome> <role> [override_reason]
set -euo pipefail

REPO_ROOT="$(pwd)"
USAGE_FILE="$REPO_ROOT/.forge/eval/usage.jsonl"

SKILL="${1:-unknown}"
OUTCOME="${2:-unknown}"
ROLE="${3:-engineer}"
OVERRIDE_REASON="${4:-}"
DATE=$(date -u +"%Y-%m-%d")
SESSION="${CLAUDE_SESSION_ID:-$(date +%s)}"

# Sanitize enum-like fields: strip to safe characters only
SKILL=$(printf '%s' "$SKILL" | tr -cd 'a-zA-Z0-9_.:/-')
OUTCOME=$(printf '%s' "$OUTCOME" | tr -cd 'a-zA-Z0-9_.:/-')
ROLE=$(printf '%s' "$ROLE" | tr -cd 'a-zA-Z0-9_.:/-')
SESSION=$(printf '%s' "$SESSION" | tr -cd 'a-zA-Z0-9_.:/-')

# Sanitize freeform text: escape backslashes first, then double quotes
OVERRIDE_REASON=$(printf '%s' "$OVERRIDE_REASON" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')

mkdir -p "$(dirname "$USAGE_FILE")"

if [ -n "$OVERRIDE_REASON" ]; then
  echo "{\"skill\":\"$SKILL\",\"outcome\":\"$OUTCOME\",\"date\":\"$DATE\",\"role\":\"$ROLE\",\"session\":\"$SESSION\",\"user_override\":true,\"override_reason\":\"$OVERRIDE_REASON\"}" >> "$USAGE_FILE"
else
  echo "{\"skill\":\"$SKILL\",\"outcome\":\"$OUTCOME\",\"date\":\"$DATE\",\"role\":\"$ROLE\",\"session\":\"$SESSION\",\"user_override\":false}" >> "$USAGE_FILE"
fi
