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
ROLE_FILE=""
if [ -f "$FORGE_DIR/roles/$ROLE.yaml" ]; then
  ROLE_FILE="$FORGE_DIR/roles/$ROLE.yaml"
elif [ -f "$PLUGIN_ROOT/templates/roles/$ROLE.yaml" ]; then
  ROLE_FILE="$PLUGIN_ROOT/templates/roles/$ROLE.yaml"
fi

if [ -n "$ROLE_FILE" ]; then
  echo "  <role-config>"
  cat "$ROLE_FILE"
  echo "  </role-config>"

  # --- Enforce gates as hard instructions ---
  echo "  <gate-enforcement>"

  # Brainstorming gate
  if grep -q 'brainstorming:[[:space:]]*true' "$ROLE_FILE" 2>/dev/null; then
    echo "    <gate name=\"brainstorming\" enforced=\"true\">"
    echo "      HARD RULE: Before creating ANY new files (Write tool) or making significant"
    echo "      code changes for a NEW feature or project, you MUST complete a brainstorming"
    echo "      phase first. This means:"
    echo "      1. Explore existing code/context silently"
    echo "      2. Ask clarifying questions ONE AT A TIME"
    echo "      3. Propose 2-3 approaches with tradeoffs"
    echo "      4. Get explicit user sign-off on an approach"
    echo "      5. Write a brief plan document"
    echo "      Only AFTER step 5 may you begin writing implementation code."
    echo "      Skip conditions: bug fixes, small changes (<1 hour), clear requirements with existing plan."
    echo "      Use skill: planning:brainstorming"
    echo "    </gate>"
  fi

  # Three-file rule gate
  if grep -q 'three_file_rule:[[:space:]]*true' "$ROLE_FILE" 2>/dev/null; then
    echo "    <gate name=\"three_file_rule\" enforced=\"true\">"
    echo "      HARD RULE: Do NOT directly read or edit more than 3 files."
    echo "      If the task requires touching >3 files, STOP and dispatch a specialist agent."
    echo "    </gate>"
  fi

  # Build verification gate
  if grep -q 'build_verification:[[:space:]]*true' "$ROLE_FILE" 2>/dev/null; then
    echo "    <gate name=\"build_verification\" enforced=\"true\">"
    echo "      HARD RULE: Before declaring any task complete, run the project build command"
    echo "      and verify it succeeds. Do not rely on type-checking alone."
    echo "    </gate>"
  fi

  # Code review gate
  if grep -q 'code_review:[[:space:]]*true' "$ROLE_FILE" 2>/dev/null; then
    echo "    <gate name=\"code_review\" enforced=\"true\">"
    echo "      HARD RULE: After significant implementation work, request code review"
    echo "      before declaring complete. Use the reviewer agent."
    echo "    </gate>"
  fi

  # Pre-dev planning gate
  if grep -q 'pre_dev_planning:[[:space:]]*true' "$ROLE_FILE" 2>/dev/null; then
    echo "    <gate name=\"pre_dev_planning\" enforced=\"true\">"
    echo "      HARD RULE: For features estimated at 2+ days, complete pre-dev planning"
    echo "      (research, PRD, TRD) before implementation. Use planning pack skills."
    echo "    </gate>"
  fi

  # Knowledge gate
  if grep -q 'knowledge_gate:[[:space:]]*true' "$ROLE_FILE" 2>/dev/null; then
    echo "    <gate name=\"knowledge_gate\" enforced=\"true\">"
    echo "      HARD RULE: Before making assumptions about conventions, patterns, or past"
    echo "      decisions, check .forge/knowledge/INDEX.md first."
    echo "    </gate>"
  fi

  echo "  </gate-enforcement>"
fi

# Suggest init if no .forge/ directory
if [ ! -d "$FORGE_DIR" ]; then
  echo "  <suggestion>No .forge/ directory found. Run /forge init to set up team knowledge.</suggestion>"
fi

echo "</forge-session>"
