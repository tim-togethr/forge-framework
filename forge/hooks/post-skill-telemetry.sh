#!/usr/bin/env bash
# Forge PostToolUse Hook — logs skill invocations automatically
# Fires after every Skill tool call. Reads tool input from stdin.
set -euo pipefail

REPO_ROOT="$(pwd)"
USAGE_FILE="$REPO_ROOT/.forge/eval/usage.jsonl"

# Ensure eval directory exists (matches telemetry.sh behavior)
mkdir -p "$(dirname "$USAGE_FILE")"

# Read hook input from stdin (JSON with tool_input)
INPUT=$(cat 2>/dev/null || echo "")
[ -z "$INPUT" ] && exit 0

# Extract skill name from tool input JSON
# Handles: {"tool_input":{"skill":"dev-cycle",...}} or {"skill":"dev-cycle",...}
SKILL=$(echo "$INPUT" | grep -o '"skill"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"skill"[[:space:]]*:[[:space:]]*"//' | sed 's/"//')
[ -z "$SKILL" ] && exit 0

# Validate skill name — only allow safe characters
[[ "$SKILL" =~ ^[a-zA-Z0-9_:.-]+$ ]] || exit 0

# Determine role
ROLE="engineer"
if [ -f "$HOME/.claude/forge-role" ]; then
  ROLE=$(tr -d '[:space:]' < "$HOME/.claude/forge-role")
fi
# Sanitize role to safe characters
ROLE=$(echo "$ROLE" | tr -cd 'a-zA-Z0-9_-')

DATE=$(date -u +"%Y-%m-%d")
SESSION="${CLAUDE_SESSION_ID:-$(date +%s)}"

echo "{\"skill\":\"$SKILL\",\"outcome\":\"triggered\",\"date\":\"$DATE\",\"role\":\"$ROLE\",\"session\":\"$SESSION\",\"user_override\":false}" >> "$USAGE_FILE"
