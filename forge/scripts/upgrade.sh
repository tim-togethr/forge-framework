#!/usr/bin/env bash
set -euo pipefail

# Forge Upgrade
# Locates the plugin, checks for updates, and optionally pulls latest.
# Usage: upgrade.sh [--check]

MODE="${1:---upgrade}"

# --- Derive own location as fallback discovery path ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELF_PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Discovery ---
PLUGIN_DIR=""
for dir in "${CLAUDE_PLUGIN_ROOT:-}" "$HOME/.claude/plugins/forge" "$SELF_PLUGIN_DIR"; do
  [ -n "$dir" ] && [ -d "$dir/.claude-plugin" ] && PLUGIN_DIR="$dir" && break
done

if [ -z "$PLUGIN_DIR" ]; then
  echo "ERROR: Forge plugin not found."
  echo "Checked: \$CLAUDE_PLUGIN_ROOT, ~/.claude/plugins/forge/, $SELF_PLUGIN_DIR"
  echo "Reinstall with: claude plugin add /path/to/forge"
  exit 1
fi

# --- Find git root ---
GIT_ROOT=$(git -C "$PLUGIN_DIR" rev-parse --show-toplevel 2>/dev/null || true)
if [ -z "$GIT_ROOT" ]; then
  echo "ERROR: Plugin directory is not inside a git repository."
  echo "Plugin: $PLUGIN_DIR"
  exit 1
fi

# --- Version ---
VERSION=$(grep '"version"' "$PLUGIN_DIR/.claude-plugin/plugin.json" 2>/dev/null \
  | sed 's/.*"version": *"//;s/".*//' || echo "unknown")

# --- Fetch and compare ---
cd "$GIT_ROOT"
LOCAL=$(git rev-parse HEAD)
if ! git fetch origin main 2>&1; then
  echo "ERROR: Could not reach remote. Check your network connection."
  exit 1
fi
REMOTE=$(git rev-parse origin/main)

LOCAL_SHORT="${LOCAL:0:7}"
REMOTE_SHORT="${REMOTE:0:7}"

if [ "$LOCAL" = "$REMOTE" ]; then
  echo "Forge is up to date"
  echo ""
  echo "  Version: v$VERSION ($LOCAL_SHORT)"
  echo "  Branch:  main"
  echo ""
  echo "Local and remote are identical — no updates available."
  exit 0
fi

# --- Update available ---
if [ "$MODE" = "--check" ]; then
  echo "Update available"
  echo ""
  echo "  Current: v$VERSION ($LOCAL_SHORT)"
  echo "  Latest:  $REMOTE_SHORT"
  echo ""
  echo "Run /forge upgrade to pull the latest version."
  exit 0
fi

# --- Pull ---
if ! git pull origin main --ff-only 2>&1; then
  echo ""
  echo "ERROR: Fast-forward pull failed. You may have local changes."
  echo "Try: cd $GIT_ROOT && git stash && git pull origin main --ff-only && git stash pop"
  exit 1
fi

NEW_VERSION=$(grep '"version"' "$PLUGIN_DIR/.claude-plugin/plugin.json" 2>/dev/null \
  | sed 's/.*"version": *"//;s/".*//' || echo "unknown")
NEW_SHORT=$(git rev-parse --short HEAD)

echo ""
echo "Forge upgraded"
echo ""
echo "  Previous: v$VERSION ($LOCAL_SHORT)"
echo "  Current:  v$NEW_VERSION ($NEW_SHORT)"
echo ""
echo "Changes:"
git log --oneline "$LOCAL..$REMOTE"
echo ""
echo "Run /clear or start a new session to pick up the changes."
