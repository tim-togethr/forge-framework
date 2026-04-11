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
echo "  <plugin-dir>$PLUGIN_ROOT</plugin-dir>"
echo "  <forge-upgrade-cmd>bash \"$PLUGIN_ROOT/scripts/upgrade.sh\"</forge-upgrade-cmd>"

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

  # ===== START GATES (before implementation) =====

  # Brainstorming gate
  if grep -q 'brainstorming:[[:space:]]*true' "$ROLE_FILE" 2>/dev/null; then
    echo "    <gate name=\"brainstorming\" phase=\"start\" enforced=\"true\">"
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

  # Pre-dev planning gate
  if grep -q 'pre_dev_planning:[[:space:]]*true' "$ROLE_FILE" 2>/dev/null; then
    echo "    <gate name=\"pre_dev_planning\" phase=\"start\" enforced=\"true\">"
    echo "      HARD RULE: For features estimated at 2+ days, complete pre-dev planning"
    echo "      (research, PRD, TRD) before implementation. Use planning pack skills."
    echo "    </gate>"
  fi

  # Knowledge gate
  if grep -q 'knowledge_gate:[[:space:]]*true' "$ROLE_FILE" 2>/dev/null; then
    echo "    <gate name=\"knowledge_gate\" phase=\"start\" enforced=\"true\">"
    echo "      HARD RULE: Before making assumptions about conventions, patterns, or past"
    echo "      decisions, check .forge/knowledge/INDEX.md first."
    echo "    </gate>"
  fi

  # ===== DURING GATES (while implementing) =====

  # Three-file rule gate
  if grep -q 'three_file_rule:[[:space:]]*true' "$ROLE_FILE" 2>/dev/null; then
    echo "    <gate name=\"three_file_rule\" phase=\"during\" enforced=\"true\">"
    echo "      HARD RULE: Do NOT directly read or edit more than 3 files."
    echo "      If the task requires touching >3 files, STOP and dispatch a specialist agent."
    echo "    </gate>"
  fi

  # Skill check gate
  if grep -q 'skill_check:[[:space:]]*true' "$ROLE_FILE" 2>/dev/null; then
    echo "    <gate name=\"skill_check\" phase=\"during\" enforced=\"true\">"
    echo "      HARD RULE: Before performing any action, check if an active pack skill"
    echo "      matches the task. If a skill exists for what you are about to do, invoke"
    echo "      it via the Skill tool instead of working from scratch. Active packs are"
    echo "      listed in <active-packs> above. Check their skills before improvising."
    echo "      Example: if writing a Dockerfile and the docker pack is active, use its"
    echo "      dockerfile-patterns skill. If writing React hooks and the react pack is"
    echo "      active, use its hooks skill."
    echo "    </gate>"
  fi

  # Dev cycle gate
  if grep -q 'dev_cycle:[[:space:]]*true' "$ROLE_FILE" 2>/dev/null; then
    echo "    <gate name=\"dev_cycle\" phase=\"during\" enforced=\"true\">"
    echo "      HARD RULE: For multi-step implementation work, follow a structured"
    echo "      development cycle. Do not jump between unrelated changes. Work through"
    echo "      one logical unit at a time: implement → verify → move to next."
    echo "      If a dev-cycle skill or command is available, use it to orchestrate."
    echo "    </gate>"
  fi

  # Auto-triggers gate
  if grep -q 'auto_triggers:[[:space:]]*true' "$ROLE_FILE" 2>/dev/null; then
    echo "    <gate name=\"auto_triggers\" phase=\"during\" enforced=\"true\">"
    echo "      HARD RULE: The following user phrases MUST trigger specific actions."
    echo "      Do NOT handle these yourself — dispatch the appropriate agent or skill."
    echo ""
    echo "      | User phrase                                    | Required action                |"
    echo "      |------------------------------------------------|--------------------------------|"
    echo "      | 'fix issues', 'fix remaining', 'address findings' | Dispatch specialist agent  |"
    echo "      | 'find where', 'search for', 'locate'           | Dispatch explore agent         |"
    echo "      | 'visualize', 'diagram', 'draw'                 | Invoke visual/diagram skill    |"
    echo "      | 'plan', 'design', 'architect'                  | Invoke brainstorm skill        |"
    echo "      | 'review', 'check my code'                      | Dispatch reviewer agent        |"
    echo ""
    echo "      If you catch yourself doing these tasks directly instead of dispatching,"
    echo "      STOP and dispatch."
    echo "    </gate>"
  fi

  # Doubt-triggered questions gate
  if grep -q 'doubt_triggered_questions:[[:space:]]*true' "$ROLE_FILE" 2>/dev/null; then
    echo "    <gate name=\"doubt_triggered_questions\" phase=\"during\" enforced=\"true\">"
    echo "      HARD RULE: When you are uncertain about the right approach, do NOT guess."
    echo "      Ask the user BEFORE proceeding. But only ask when ALL of these are true:"
    echo "      - You cannot resolve from CLAUDE.md, repo conventions, or codebase patterns"
    echo "      - Multiple approaches are genuinely viable"
    echo "      - The choice significantly impacts correctness"
    echo "      - Getting it wrong wastes substantial effort"
    echo ""
    echo "      When asking, show your work:"
    echo "      GOOD: 'Found PostgreSQL in docker-compose but MongoDB in docs."
    echo "             This feature needs time-series. Which should I extend?'"
    echo "      BAD:  'Which database should I use?'"
    echo ""
    echo "      If proceeding without asking: state your assumption, explain why,"
    echo "      and note what would change it."
    echo "    </gate>"
  fi

  # Visual companion gate
  if grep -q 'visual_companion:[[:space:]]*true' "$ROLE_FILE" 2>/dev/null; then
    echo "    <gate name=\"visual_companion\" phase=\"during\" enforced=\"true\">"
    echo "      HARD RULE: When explaining complex systems, architecture, data flows,"
    echo "      or multi-step processes, use visual aids — not walls of text."
    echo "      - For architecture or flows: generate a Mermaid diagram"
    echo "      - For comparisons or data: use an HTML table or visual-explainer"
    echo "      - For complex ASCII tables (4+ rows, 3+ columns): use styled HTML instead"
    echo "      If a diagram/visual skill is available, use it."
    echo "    </gate>"
  fi

  # Design system gate
  if grep -q 'design_system:[[:space:]]*true' "$ROLE_FILE" 2>/dev/null; then
    echo "    <gate name=\"design_system\" phase=\"during\" enforced=\"true\">"
    echo "      HARD RULE: All UI work MUST follow the project's design system."
    echo "      Before creating or modifying components, check for:"
    echo "      - Existing design tokens (colors, spacing, typography)"
    echo "      - Component library patterns already in use"
    echo "      - Naming conventions for CSS classes, variants, and props"
    echo "      Do NOT invent new colors, spacing values, or component patterns"
    echo "      when the design system already provides them. If the design system"
    echo "      is missing something, flag it — do not silently deviate."
    echo "    </gate>"
  fi

  # Accessibility gates
  if grep -q 'accessibility_gates:[[:space:]]*true' "$ROLE_FILE" 2>/dev/null; then
    echo "    <gate name=\"accessibility_gates\" phase=\"during\" enforced=\"true\">"
    echo "      HARD RULE: All UI output MUST meet WCAG 2.1 AA standards."
    echo "      - Every interactive element needs keyboard access and visible focus"
    echo "      - Every image needs alt text; decorative images need alt=\"\""
    echo "      - Color contrast ratios: 4.5:1 for normal text, 3:1 for large text"
    echo "      - Form inputs need associated labels (not just placeholders)"
    echo "      - Use semantic HTML (nav, main, article, button) not div soup"
    echo "      - ARIA attributes only when semantic HTML is insufficient"
    echo "      If an accessibility audit skill is available, run it before handoff."
    echo "    </gate>"
  fi

  # ===== TELEMETRY GATE (always active when role config exists) =====

  PLUGIN_EVAL_DIR="$PLUGIN_ROOT/eval"
  echo "    <gate name=\"telemetry\" phase=\"during\" enforced=\"true\">"
  echo "      HARD RULE: After completing work triggered by any Skill tool invocation,"
  echo "      you MUST log the outcome by running this command:"
  echo ""
  echo "        bash $PLUGIN_EVAL_DIR/telemetry.sh SKILL_NAME OUTCOME CURRENT_ROLE"
  echo ""
  echo "      Replace the placeholders:"
  echo "        - SKILL_NAME  — the skill that was invoked (e.g. dev-cycle, brainstorming)"
  echo "        - OUTCOME     — one of: completed, skipped, overridden"
  echo "        - CURRENT_ROLE — read from ~/.claude/forge-role, or 'engineer' if absent"
  echo ""
  echo "      If the user explicitly overrides a skill, add the reason as a 4th argument:"
  echo "        bash $PLUGIN_EVAL_DIR/telemetry.sh SKILL_NAME overridden CURRENT_ROLE \"reason\""
  echo ""
  echo "      This fires AFTER the PostToolUse hook has already logged the trigger."
  echo "      Your job is to record how it resolved. Do not skip this."
  echo "    </gate>"

  # ===== COMPLETION GATES (before handoff) =====
  # These gates define what you MUST do before telling the user the work is done.
  # The user is NOT your tester. You must verify your own work.

  COMPLETION_STEPS=""

  if grep -q 'build_verification:[[:space:]]*true' "$ROLE_FILE" 2>/dev/null; then
    COMPLETION_STEPS="${COMPLETION_STEPS}BUILD,"
  fi
  if grep -q 'test_gate:[[:space:]]*true' "$ROLE_FILE" 2>/dev/null; then
    COMPLETION_STEPS="${COMPLETION_STEPS}TEST,"
  fi
  if grep -q 'code_review:[[:space:]]*true' "$ROLE_FILE" 2>/dev/null; then
    COMPLETION_STEPS="${COMPLETION_STEPS}REVIEW,"
  fi

  if [ -n "$COMPLETION_STEPS" ]; then
    echo "    <gate name=\"completion_checklist\" phase=\"end\" enforced=\"true\">"
    echo "      HARD RULE — MANDATORY COMPLETION CHECKLIST"
    echo "      ==========================================="
    echo "      You MUST NOT tell the user that work is done, hand off, or summarize"
    echo "      your changes until you have completed EVERY step below. The user is"
    echo "      NOT your tester. Handing off untested, unreviewed, or broken code is"
    echo "      a failure."
    echo ""
    echo "      Before saying 'done', 'complete', 'finished', 'ready', or similar:"
    echo ""

    STEP_NUM=1

    if echo "$COMPLETION_STEPS" | grep -q "BUILD"; then
      echo "      ${STEP_NUM}. BUILD: Run the project build command (e.g. npm run build, go build)."
      echo "         Verify it exits with 0 and produces no errors. If it fails, fix it."
      echo "         Do NOT skip this. Do NOT say 'the build should work'."
      STEP_NUM=$((STEP_NUM + 1))
    fi

    if echo "$COMPLETION_STEPS" | grep -q "TEST"; then
      echo "      ${STEP_NUM}. TEST: Run the project test suite (e.g. npm test, go test ./...)."
      echo "         If tests fail, fix them. If new code has no tests, write them."
      echo "         Do NOT say 'you can run the tests to verify' — YOU run them."
      STEP_NUM=$((STEP_NUM + 1))
    fi

    if echo "$COMPLETION_STEPS" | grep -q "REVIEW"; then
      echo "      ${STEP_NUM}. REVIEW: Dispatch a reviewer agent to check your changes."
      echo "         Review the feedback. Fix any issues found. Do NOT hand off"
      echo "         review findings as a TODO list for the user."
      STEP_NUM=$((STEP_NUM + 1))
    fi

    echo ""
    echo "      Only after ALL steps above pass may you present results to the user."
    echo "      If any step fails, fix the issue and re-run that step."
    echo "    </gate>"
  fi

  echo "  </gate-enforcement>"
fi

# Suggest init if no .forge/ directory
if [ ! -d "$FORGE_DIR" ]; then
  echo "  <suggestion>No .forge/ directory found. Run /forge init to set up team knowledge.</suggestion>"
fi

echo "</forge-session>"
