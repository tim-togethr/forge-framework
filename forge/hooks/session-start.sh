#!/usr/bin/env bash
# Forge Session Start Hook
# Runs detection, loads knowledge index, outputs session context.
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(pwd)"
FORGE_DIR="$REPO_ROOT/.forge"

# --- Detect active packs ---
PACKS_JSON=$("$PLUGIN_ROOT/core/detection.sh" "$REPO_ROOT" 2>/dev/null || echo "[]")

# --- Determine role ---
ROLE="engineer"
if [ -f "$HOME/.claude/forge-role" ]; then
  ROLE=$(cat "$HOME/.claude/forge-role" | tr -d '[:space:]')
fi
if [ -f "$FORGE_DIR/forge.yaml" ] && [ "$ROLE" = "engineer" ]; then
  YAML_ROLE=$(grep '^default_role:' "$FORGE_DIR/forge.yaml" 2>/dev/null | sed 's/^default_role:[[:space:]]*//' | tr -d '[:space:]')
  [ -n "$YAML_ROLE" ] && ROLE="$YAML_ROLE"
fi

# --- Build context output ---
echo "<forge-session>"
echo "  <active-packs>$PACKS_JSON</active-packs>"
echo "  <role>$ROLE</role>"

# Load knowledge index if it exists
if [ -f "$FORGE_DIR/knowledge/INDEX.md" ]; then
  echo "  <knowledge>"
  cat "$FORGE_DIR/knowledge/INDEX.md"
  echo "  </knowledge>"
fi

# Load role config if it exists
if [ -f "$FORGE_DIR/roles/$ROLE.yaml" ]; then
  echo "  <role-config>"
  cat "$FORGE_DIR/roles/$ROLE.yaml"
  echo "  </role-config>"
fi

# Suggest init if no .forge/ directory
if [ ! -d "$FORGE_DIR" ]; then
  echo "  <suggestion>No .forge/ directory found. Run /forge init to set up team knowledge.</suggestion>"
fi

echo "</forge-session>"
