# Forge Framework Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Claude Code plugin that unifies Ring + ECC + Superpowers into a single framework with progressive disclosure, shared team knowledge, and self-improvement.

**Architecture:** Two-layer system — a globally installed plugin (engine) and a per-repo `.forge/` directory (knowledge). The plugin provides the core orchestrator (~300 tokens), auto-detection engine, domain packs, and eval system. The repo directory provides team knowledge, project skills, role configs, and eval data.

**Tech Stack:** Markdown (skills, agents, commands), YAML (pack manifests, role configs), JSON (plugin manifest, hooks), Bash (detection engine, telemetry hooks)

**Spec:** `docs/specs/2026-04-09-forge-framework-design.md`

---

## Code Review Checkpoint

After completing each phase, pause for review before starting the next. Phases are:

1. Plugin Skeleton & Core (Tasks 1-4)
2. Hooks & Shared Agents (Tasks 5-7)
3. First Pack + Validation (Tasks 8-10)
4. Stack Packs (Tasks 11-17)
5. Domain Packs (Tasks 18-21)
6. Commands (Tasks 22-24)
7. Eval System (Tasks 25-26)
8. Role Config Templates & Polish (Tasks 27-29)

---

## Phase 1: Plugin Skeleton & Core

### Task 1: Plugin Manifest & Directory Structure

**Files:**
- Create: `forge/.claude-plugin/plugin.json`
- Create: `forge/.gitkeep` files for empty directories

- [ ] **Step 1: Create the full directory scaffold**

```bash
cd /Users/timcollins/forge-framework
mkdir -p forge/.claude-plugin
mkdir -p forge/core
mkdir -p forge/agents
mkdir -p forge/packs
mkdir -p forge/hooks
mkdir -p forge/commands
mkdir -p forge/eval
```

- [ ] **Step 2: Create plugin.json**

Create `forge/.claude-plugin/plugin.json`:

```json
{
  "name": "forge",
  "displayName": "Forge",
  "description": "Unified skills & agent framework for Claude Code. Progressive disclosure, shared team knowledge, auto-detected domain packs, self-improvement loop.",
  "version": "0.1.0",
  "author": {
    "name": "tim-togethr"
  },
  "repository": "https://github.com/tim-togethr/forge-framework",
  "license": "MIT",
  "keywords": [
    "skills",
    "agents",
    "orchestrator",
    "progressive-disclosure",
    "team-knowledge",
    "auto-detection",
    "self-eval"
  ],
  "skills": "./packs/",
  "agents": [
    "./agents/explorer.md",
    "./agents/planner.md",
    "./agents/reviewer.md"
  ],
  "commands": "./commands/"
}
```

- [ ] **Step 3: Verify JSON is valid**

Run: `cd /Users/timcollins/forge-framework && python3 -c "import json; json.load(open('forge/.claude-plugin/plugin.json')); print('OK')"`
Expected: `OK`

- [ ] **Step 4: Commit**

```bash
cd /Users/timcollins/forge-framework
git add forge/.claude-plugin/plugin.json
git commit -m "feat: add plugin manifest and directory scaffold"
```

---

### Task 2: Core Orchestrator

**Files:**
- Create: `forge/core/orchestrator.md`

This is the ~300 token always-loaded file. It must be concise — every word costs tokens.

- [ ] **Step 1: Write orchestrator.md**

Create `forge/core/orchestrator.md`:

```markdown
---
name: forge:orchestrator
description: |
  Core orchestrator for Forge framework. Enforces mandatory gates,
  progressive disclosure, and team knowledge integration.
---

# Forge Orchestrator

## Hard Gates

1. **3-File Rule** — Touched >3 files? STOP. Dispatch agent. No exceptions.
2. **Skill Check** — Before any action, check if an active pack skill matches. If yes, invoke it.
3. **Role Gates** — Load `.forge/roles/{role}.yaml`. Enforce only gates assigned to this role.
4. **Knowledge First** — Before making assumptions about conventions, patterns, or past decisions, check `.forge/knowledge/INDEX.md`.

## Auto-Triggers

| User phrase | Action |
|-------------|--------|
| "fix issues", "fix remaining", "address findings" | Dispatch specialist agent |
| "find where", "search for", "locate" | Dispatch explore agent |
| "visualize", "diagram" | Invoke visual skill |
| "plan", "design", "architect" | Invoke brainstorm skill |

## Precedence

- Project skill (`.forge/skills/`) > pack skill (`packs/`)
- Newer knowledge entry (`added_date`) > older
- Same date conflict → ask user to resolve

## Progressive Disclosure

Skills are loaded in three tiers:
1. **Metadata** (always loaded) — name + one-line description (~20 tokens/skill)
2. **Instructions** (on invoke) — full SKILL.md content
3. **Resources** (on demand) — shared patterns, scripts, references

Only Tier 1 is in context at session start. Tier 2 loads via Skill tool. Tier 3 loads via Read tool within the skill.

## Session Start

1. Load this orchestrator
2. Run `detection.sh` → identify active packs
3. Load `.forge/knowledge/INDEX.md` (respect `knowledge_budget`)
4. Load `.forge/roles/{role}.yaml` for gate config
5. Inject Tier 1 metadata for all active pack skills
```

- [ ] **Step 2: Count tokens to verify budget**

Run: `wc -w forge/core/orchestrator.md`
Expected: Under 250 words (~300 tokens). Adjust if over.

- [ ] **Step 3: Commit**

```bash
cd /Users/timcollins/forge-framework
git add forge/core/orchestrator.md
git commit -m "feat: add core orchestrator (~300 tokens)"
```

---

### Task 3: Detection Engine

**Files:**
- Create: `forge/core/detection.sh`
- Create: `tests/test-detection.sh`

- [ ] **Step 1: Write the test script**

Create `tests/test-detection.sh`:

```bash
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
    ((PASS++))
  else
    echo "  FAIL: $pack NOT detected in $dir"
    ((FAIL++))
  fi
}

assert_not_detected() {
  local pack="$1" dir="$2"
  if "$DETECTION" "$dir" 2>/dev/null | grep -q "\"$pack\""; then
    echo "  FAIL: $pack should NOT be detected in $dir"
    ((FAIL++))
  else
    echo "  PASS: $pack correctly not detected in $dir"
    ((PASS++))
  fi
}

# Setup test fixtures
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

# Cleanup
rm -rf "$FIXTURES"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] || exit 1
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `chmod +x tests/test-detection.sh && bash tests/test-detection.sh`
Expected: FAIL (detection.sh doesn't exist yet)

- [ ] **Step 3: Write detection.sh**

Create `forge/core/detection.sh`:

```bash
#!/usr/bin/env bash
# Forge Detection Engine
# Scans a repo directory and outputs JSON array of activated pack names.
# Usage: detection.sh /path/to/repo
set -euo pipefail

REPO_DIR="${1:-.}"
FORGE_DIR="$REPO_DIR/.forge"
DETECTED=()

# --- File-based detection ---

# nextjs
if ls "$REPO_DIR"/next.config.* 1>/dev/null 2>&1 || \
   [ -d "$REPO_DIR/src/app" ]; then
  DETECTED+=("nextjs")
fi

# react (check package.json deps, but not if nextjs already covers it — still add it)
if [ -f "$REPO_DIR/package.json" ] && grep -q '"react"' "$REPO_DIR/package.json" 2>/dev/null; then
  DETECTED+=("react")
fi

# supabase
if [ -f "$REPO_DIR/supabase/config.toml" ] || \
   [ -d "$REPO_DIR/supabase/migrations" ] || \
   ([ -f "$REPO_DIR/package.json" ] && grep -q '@supabase/supabase-js' "$REPO_DIR/package.json" 2>/dev/null); then
  DETECTED+=("supabase")
fi

# tailwind
if ls "$REPO_DIR"/tailwind.config.* 1>/dev/null 2>&1 || \
   ([ -f "$REPO_DIR/package.json" ] && grep -q '"tailwindcss"' "$REPO_DIR/package.json" 2>/dev/null); then
  DETECTED+=("tailwind")
fi

# typescript
if [ -f "$REPO_DIR/tsconfig.json" ] || \
   ([ -f "$REPO_DIR/package.json" ] && grep -q '"typescript"' "$REPO_DIR/package.json" 2>/dev/null); then
  DETECTED+=("typescript")
fi

# golang
if [ -f "$REPO_DIR/go.mod" ]; then
  DETECTED+=("golang")
fi

# python
if [ -f "$REPO_DIR/pyproject.toml" ] || \
   [ -f "$REPO_DIR/requirements.txt" ] || \
   [ -f "$REPO_DIR/setup.py" ]; then
  DETECTED+=("python")
fi

# docker
if [ -f "$REPO_DIR/Dockerfile" ] || \
   ls "$REPO_DIR"/docker-compose.* 1>/dev/null 2>&1; then
  DETECTED+=("docker")
fi

# --- forge.yaml overrides ---

if [ -f "$FORGE_DIR/forge.yaml" ]; then
  # Add extra_packs
  if grep -q 'extra_packs:' "$FORGE_DIR/forge.yaml" 2>/dev/null; then
    while IFS= read -r line; do
      pack=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*//' | tr -d '[:space:]')
      if [ -n "$pack" ] && [[ ! " ${DETECTED[*]:-} " =~ " $pack " ]]; then
        DETECTED+=("$pack")
      fi
    done < <(sed -n '/^extra_packs:/,/^[^ ]/{ /^  *-/p }' "$FORGE_DIR/forge.yaml")
  fi

  # Remove suppress_packs
  if grep -q 'suppress_packs:' "$FORGE_DIR/forge.yaml" 2>/dev/null; then
    SUPPRESSED=()
    while IFS= read -r line; do
      pack=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*//' | sed 's/[[:space:]]*#.*//' | tr -d '[:space:]')
      [ -n "$pack" ] && SUPPRESSED+=("$pack")
    done < <(sed -n '/^suppress_packs:/,/^[^ ]/{ /^  *-/p }' "$FORGE_DIR/forge.yaml")

    FILTERED=()
    for pack in "${DETECTED[@]}"; do
      if [[ ! " ${SUPPRESSED[*]:-} " =~ " $pack " ]]; then
        FILTERED+=("$pack")
      fi
    done
    DETECTED=("${FILTERED[@]}")
  fi
fi

# --- Output JSON array ---

if [ ${#DETECTED[@]} -eq 0 ]; then
  echo "[]"
else
  printf '['
  for i in "${!DETECTED[@]}"; do
    [ "$i" -gt 0 ] && printf ','
    printf '"%s"' "${DETECTED[$i]}"
  done
  printf ']\n'
fi
```

- [ ] **Step 4: Run the tests**

Run: `chmod +x forge/core/detection.sh && bash tests/test-detection.sh`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
cd /Users/timcollins/forge-framework
git add forge/core/detection.sh tests/test-detection.sh
git commit -m "feat: add detection engine with tests"
```

---

### Task 4: Pack Loader

**Files:**
- Create: `forge/core/pack-loader.md`

- [ ] **Step 1: Write pack-loader.md**

Create `forge/core/pack-loader.md`:

```markdown
---
name: forge:pack-loader
description: |
  Progressive disclosure loader for Forge packs. Generates Tier 1 metadata
  from activated packs and injects into session context.
---

# Pack Loader

## How Packs Work

Each pack directory under `packs/` contains:
- `pack.yaml` — metadata and detection rules
- `skills/` — SKILL.md files (one per skill subdirectory)
- `agents/` — agent .md files (optional)
- `shared-patterns/` — reference docs loaded on demand (optional)

## Tier 1: Metadata Generation

At session start, for each activated pack, the loader reads every `skills/*/SKILL.md` and extracts:
- `name` from frontmatter
- `description` first line from frontmatter

These are concatenated into a compact skill catalog:

```
## Active Skills

**nextjs:** app-router (App Router patterns), server-components (RSC data fetching), api-routes (API route handlers), ...
**react:** component-patterns (React component best practices), hooks (Custom hook patterns), ...
**supabase:** schema-design (Database schema patterns), rls-policies (Row-Level Security), ...
```

Each skill is name + parenthetical summary. ~20 tokens per skill.

## Tier 2: Skill Loading

When the orchestrator determines a skill should fire:
1. Read the full `SKILL.md` from the pack's `skills/{name}/SKILL.md`
2. Inject into context via the Skill tool
3. Follow the skill's instructions

## Tier 3: Resource Loading

Skills that reference shared patterns or resources:
1. Skill instructions say "Read `shared-patterns/pattern-name.md`"
2. Agent reads the file on demand
3. Content enters context only when needed

## Pack Skill Format

Every skill in a pack follows this SKILL.md frontmatter:

```yaml
---
name: packname:skill-name
description: One-line description under 80 characters
trigger: |
  - When this skill should fire
  - Conditions or user phrases
skip_when: |
  - When this skill should NOT fire
---
```

Body is standard skill markdown with sections, checklists, and code examples.

## Pack Agent Format

Agents in packs follow standard agent frontmatter:

```yaml
---
name: packname:agent-name
description: What this agent does
type: reviewer | builder | analyzer
tools: ["Read", "Grep", "Glob"]
---
```
```

- [ ] **Step 2: Commit**

```bash
cd /Users/timcollins/forge-framework
git add forge/core/pack-loader.md
git commit -m "feat: add pack loader with progressive disclosure spec"
```

---

## Phase 2: Hooks & Shared Agents

### Task 5: Hooks Configuration

**Files:**
- Create: `forge/hooks/hooks.json`
- Create: `forge/hooks/session-start.sh`

- [ ] **Step 1: Write hooks.json**

Create `forge/hooks/hooks.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "clear|compact|startup|resume",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/session-start.sh"
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 2: Write session-start.sh**

Create `forge/hooks/session-start.sh`:

```bash
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
```

- [ ] **Step 3: Make executable and verify**

Run: `chmod +x forge/hooks/session-start.sh && python3 -c "import json; json.load(open('forge/hooks/hooks.json')); print('OK')"`
Expected: `OK`

- [ ] **Step 4: Commit**

```bash
cd /Users/timcollins/forge-framework
git add forge/hooks/hooks.json forge/hooks/session-start.sh
git commit -m "feat: add session-start hook with detection and knowledge loading"
```

---

### Task 6: Explorer Agent

**Files:**
- Create: `forge/agents/explorer.md`

- [ ] **Step 1: Write explorer.md**

Create `forge/agents/explorer.md`:

```markdown
---
name: forge:explorer
description: "Fast codebase exploration agent. Use for finding files, searching code, understanding architecture, and answering questions about the codebase."
type: explorer
tools: ["Read", "Grep", "Glob", "Bash"]
---

# Forge Explorer

You are a fast codebase exploration agent dispatched by the Forge orchestrator.

## Your Role

Find information quickly and report back. You do NOT modify code.

## Before Searching

Check `.forge/knowledge/INDEX.md` first — the answer may already be documented as a team decision, convention, or gotcha.

## Approach

1. Start with the most specific search (exact filename, function name, symbol)
2. Widen only if the specific search fails
3. Report findings with exact file paths and line numbers
4. If the answer relates to a team convention, quote the relevant knowledge entry

## Output

Keep reports concise. Include:
- Exact file paths with line numbers
- Relevant code snippets (minimal, not entire files)
- Cross-references to `.forge/knowledge/` entries if applicable
```

- [ ] **Step 2: Commit**

```bash
cd /Users/timcollins/forge-framework
git add forge/agents/explorer.md
git commit -m "feat: add explorer agent"
```

---

### Task 7: Planner and Reviewer Agents

**Files:**
- Create: `forge/agents/planner.md`
- Create: `forge/agents/reviewer.md`

- [ ] **Step 1: Write planner.md**

Create `forge/agents/planner.md`:

```markdown
---
name: forge:planner
description: "Implementation planning agent. Designs step-by-step plans, identifies critical files, and considers architectural trade-offs."
type: planner
tools: ["Read", "Grep", "Glob"]
---

# Forge Planner

You are an implementation planning agent dispatched by the Forge orchestrator.

## Your Role

Create detailed, actionable implementation plans. You do NOT write code directly.

## Before Planning

1. Check `.forge/knowledge/INDEX.md` for relevant decisions and conventions
2. Check `.forge/skills/` for project-specific workflows that apply
3. Understand existing patterns before proposing new ones

## Output

Plans must include:
- File paths for every change
- Step-by-step tasks (2-5 minutes each)
- Test strategy per component
- Commit points after each logical chunk
```

- [ ] **Step 2: Write reviewer.md**

Create `forge/agents/reviewer.md`:

```markdown
---
name: forge:reviewer
description: "Code review agent. Reviews quality, architecture, security, and correctness. Reports issues with severity ratings."
type: reviewer
tools: ["Read", "Grep", "Glob", "Bash"]
output_schema:
  format: markdown
  required_sections:
    - name: "VERDICT"
      pattern: "^## VERDICT: (PASS|FAIL|NEEDS_DISCUSSION)$"
      required: true
    - name: "Issues Found"
      pattern: "^## Issues Found"
      required: true
  verdict_values: ["PASS", "FAIL", "NEEDS_DISCUSSION"]
---

# Forge Reviewer

You are a code review agent dispatched by the Forge orchestrator.

## Your Role

Review code changes for quality, security, and correctness. You REPORT issues — you do NOT fix them.

## Before Reviewing

Check `.forge/knowledge/` for:
- **conventions/** — does the code follow established patterns?
- **gotchas/** — does the code avoid known pitfalls?
- **decisions/** — does the code align with architectural decisions?

## Review Checklist

1. **Correctness** — Does it do what it claims?
2. **Conventions** — Does it follow `.forge/knowledge/conventions/`?
3. **Gotchas** — Does it avoid `.forge/knowledge/gotchas/`?
4. **Security** — Input validation, auth checks, injection risks
5. **Tests** — Are changes tested? Are edge cases covered?

## Severity Levels

| Level | Meaning |
|-------|---------|
| CRITICAL | Breaks functionality, security vulnerability, data loss risk |
| HIGH | Logic error, missing validation, convention violation |
| MEDIUM | Code quality, maintainability, minor convention deviation |
| LOW | Style, naming, documentation |

## Output Format

```markdown
## VERDICT: [PASS | FAIL | NEEDS_DISCUSSION]

## Issues Found
- Critical: [N]
- High: [N]
- Medium: [N]
- Low: [N]

## Details
[Issue list with file:line references]

## What Was Done Well
[Positive observations]
```
```

- [ ] **Step 3: Commit**

```bash
cd /Users/timcollins/forge-framework
git add forge/agents/planner.md forge/agents/reviewer.md
git commit -m "feat: add planner and reviewer agents"
```

---

## Phase 3: First Pack + Validation

### Task 8: Pack YAML Schema & Validation Script

**Files:**
- Create: `tests/validate-pack.sh`

This script validates any pack directory follows the correct format.

- [ ] **Step 1: Write validate-pack.sh**

Create `tests/validate-pack.sh`:

```bash
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
    ((ERRORS++))
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
      # detect: is optional for opt-in packs
      if [ "$field" = "detect:" ]; then
        echo "  SKIP: pack.yaml missing $field (opt-in pack)"
      else
        echo "  FAIL: pack.yaml missing $field"
        ((ERRORS++))
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
    ((ERRORS++))
  fi

  # Each SKILL.md has required frontmatter
  for skill_file in $(find "$PACK_DIR/skills" -name "SKILL.md"); do
    skill_name=$(basename "$(dirname "$skill_file")")
    if head -5 "$skill_file" | grep -q "^name:"; then
      echo "  OK: $skill_name has name field"
    else
      echo "  FAIL: $skill_name missing name field"
      ((ERRORS++))
    fi
    if head -10 "$skill_file" | grep -q "^description:"; then
      echo "  OK: $skill_name has description field"
    else
      echo "  FAIL: $skill_name missing description field"
      ((ERRORS++))
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
```

- [ ] **Step 2: Make executable**

Run: `chmod +x tests/validate-pack.sh`

- [ ] **Step 3: Commit**

```bash
cd /Users/timcollins/forge-framework
git add tests/validate-pack.sh
git commit -m "feat: add pack validation script"
```

---

### Task 9: TypeScript Pack (First Pack)

**Files:**
- Create: `forge/packs/typescript/pack.yaml`
- Create: `forge/packs/typescript/skills/type-safety/SKILL.md`
- Create: `forge/packs/typescript/skills/strict-mode/SKILL.md`

- [ ] **Step 1: Write pack.yaml**

Create `forge/packs/typescript/pack.yaml`:

```yaml
name: typescript
description: TypeScript development patterns, type safety, and configuration
detect:
  files: ["tsconfig.json"]
  deps: ["typescript"]
roles: [engineer]
```

- [ ] **Step 2: Write type-safety skill**

Create `forge/packs/typescript/skills/type-safety/SKILL.md`:

```markdown
---
name: typescript:type-safety
description: TypeScript type safety patterns — strict types, generics, narrowing, branded types
trigger: |
  - Writing new TypeScript interfaces or types
  - Type errors or "any" usage detected
  - User asks about type patterns
skip_when: |
  - JavaScript-only files (no .ts/.tsx)
  - Type definitions already complete and correct
---

# Type Safety Patterns

## Core Rules

1. **No `any`** — Use `unknown` for truly unknown types, then narrow
2. **Strict mode** — `tsconfig.json` must have `"strict": true`
3. **Exhaustive switches** — Use `never` for exhaustiveness checking
4. **Branded types** — Use branded types for domain IDs to prevent mixing

## Narrowing Patterns

```typescript
// Narrow unknown to specific type
function processInput(input: unknown): string {
  if (typeof input === "string") return input;
  if (typeof input === "number") return String(input);
  throw new Error(`Unexpected input type: ${typeof input}`);
}

// Discriminated unions
type Result<T> = { ok: true; value: T } | { ok: false; error: string };
```

## Branded Types

```typescript
type UserId = string & { readonly __brand: "UserId" };
type CompanyId = string & { readonly __brand: "CompanyId" };

function createUserId(id: string): UserId { return id as UserId; }
// Prevents: getUserById(companyId) — type error
```

## Checklist

- [ ] No `any` in changed files
- [ ] All switch statements have `default: never` exhaustiveness
- [ ] API response types match actual response shapes
- [ ] Utility types used where appropriate (`Partial`, `Pick`, `Omit`)
```

- [ ] **Step 3: Write strict-mode skill**

Create `forge/packs/typescript/skills/strict-mode/SKILL.md`:

```markdown
---
name: typescript:strict-mode
description: TypeScript strict configuration — compiler options and project setup
trigger: |
  - New TypeScript project setup
  - tsconfig.json modifications
  - Build errors related to strict mode
skip_when: |
  - tsconfig.json already has strict: true and project builds clean
---

# TypeScript Strict Mode

## Required tsconfig.json Settings

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "forceConsistentCasingInFileNames": true
  }
}
```

## What `strict: true` Enables

| Flag | What It Catches |
|------|-----------------|
| `strictNullChecks` | `null` and `undefined` not assignable to other types |
| `strictFunctionTypes` | Contravariant parameter checking |
| `strictBindCallApply` | Correct types for `bind`, `call`, `apply` |
| `strictPropertyInitialization` | Class properties must be initialized |
| `noImplicitAny` | Must declare types, no implicit `any` |
| `noImplicitThis` | `this` must have explicit type in functions |
| `alwaysStrict` | Emit `"use strict"` in all files |

## Checklist

- [ ] `strict: true` in tsconfig.json
- [ ] `noUncheckedIndexedAccess: true` for safe array/object access
- [ ] No `// @ts-ignore` or `// @ts-expect-error` without explanation
```

- [ ] **Step 4: Validate the pack**

Run: `bash tests/validate-pack.sh forge/packs/typescript`
Expected: `=== PASS: typescript is valid ===`

- [ ] **Step 5: Commit**

```bash
cd /Users/timcollins/forge-framework
git add forge/packs/typescript/
git commit -m "feat: add typescript pack (first pack, validates format)"
```

---

### Task 10: Next.js Pack

**Files:**
- Create: `forge/packs/nextjs/pack.yaml`
- Create: `forge/packs/nextjs/skills/app-router/SKILL.md`
- Create: `forge/packs/nextjs/skills/server-components/SKILL.md`
- Create: `forge/packs/nextjs/skills/api-routes/SKILL.md`

- [ ] **Step 1: Write pack.yaml**

Create `forge/packs/nextjs/pack.yaml`:

```yaml
name: nextjs
description: Next.js 14/15 App Router patterns, server components, and API routes
detect:
  files: ["next.config.*"]
  deps: ["next"]
  dirs: ["src/app/"]
roles: [engineer, designer]
```

- [ ] **Step 2: Write app-router skill**

Create `forge/packs/nextjs/skills/app-router/SKILL.md`:

```markdown
---
name: nextjs:app-router
description: Next.js App Router patterns — layouts, loading states, error boundaries, parallel routes
trigger: |
  - Creating new pages or routes in src/app/
  - Route organization questions
  - Layout or loading state implementation
skip_when: |
  - Pages Router project (no src/app/ directory)
---

# App Router Patterns

## Route Structure

```
src/app/
├── layout.tsx          # Root layout (required)
├── page.tsx            # Home page
├── loading.tsx         # Loading UI (Suspense boundary)
├── error.tsx           # Error boundary
├── not-found.tsx       # 404 page
├── dashboard/
│   ├── layout.tsx      # Dashboard layout (nested)
│   ├── page.tsx        # /dashboard
│   └── settings/
│       └── page.tsx    # /dashboard/settings
└── api/
    └── route.ts        # API route handler
```

## Key Rules

1. **Layouts persist** — they don't re-render on navigation. Put shared UI here.
2. **`page.tsx` is required** — a directory is only a route if it has `page.tsx`
3. **Loading states** — `loading.tsx` auto-wraps `page.tsx` in Suspense
4. **Error boundaries** — `error.tsx` must be a client component (`"use client"`)
5. **Metadata** — export `metadata` object or `generateMetadata()` function from `page.tsx` or `layout.tsx`

## Dynamic Routes

```typescript
// src/app/users/[id]/page.tsx
export default async function UserPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params; // Next.js 15: params is a Promise
  const user = await getUser(id);
  return <UserProfile user={user} />;
}
```

## Checklist

- [ ] Every route directory has a `page.tsx`
- [ ] Layouts don't fetch user-specific data (they persist across navigations)
- [ ] Dynamic params awaited (Next.js 15+ requirement)
- [ ] Error boundaries are client components
- [ ] Loading states exist for data-fetching pages
```

- [ ] **Step 3: Write server-components skill**

Create `forge/packs/nextjs/skills/server-components/SKILL.md`:

```markdown
---
name: nextjs:server-components
description: React Server Components — data fetching, streaming, client/server boundaries
trigger: |
  - Data fetching in components
  - "use client" boundary decisions
  - Streaming or Suspense implementation
skip_when: |
  - Pure client-side SPA (no server rendering)
---

# Server Components

## Key Rules

1. **Server by default** — All components in App Router are Server Components unless marked `"use client"`
2. **No hooks in SC** — `useState`, `useEffect`, etc. are client-only
3. **Fetch in SC** — Data fetching belongs in Server Components, not in `useEffect`
4. **Push client boundary down** — Only the interactive leaf needs `"use client"`, not the whole tree

## Data Fetching

```typescript
// Server Component — fetch directly, no useEffect
export default async function DashboardPage() {
  const data = await fetch("https://api.example.com/stats");
  const stats = await data.json();
  return <StatsDisplay stats={stats} />;
}
```

## Client Boundary

```typescript
// Only the interactive part is a client component
"use client";
export function LikeButton({ postId }: { postId: string }) {
  const [liked, setLiked] = useState(false);
  return <button onClick={() => setLiked(!liked)}>Like</button>;
}

// Parent stays as Server Component
export default async function PostPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const post = await getPost(id);
  return (
    <article>
      <h1>{post.title}</h1>
      <p>{post.body}</p>
      <LikeButton postId={id} /> {/* Client island */}
    </article>
  );
}
```

## Checklist

- [ ] Data fetching happens in Server Components (not useEffect)
- [ ] `"use client"` only on components that need interactivity
- [ ] No server-only imports (DB clients, secrets) in client components
- [ ] Suspense boundaries around async Server Components for streaming
```

- [ ] **Step 4: Write api-routes skill**

Create `forge/packs/nextjs/skills/api-routes/SKILL.md`:

```markdown
---
name: nextjs:api-routes
description: Next.js API route handlers — request handling, validation, error responses
trigger: |
  - Creating or modifying API routes in src/app/api/
  - API error handling questions
  - Request validation implementation
skip_when: |
  - External API (not Next.js route handlers)
---

# API Route Handlers

## Structure

```typescript
// src/app/api/users/route.ts
import { NextRequest, NextResponse } from "next/server";

export async function GET(request: NextRequest) {
  const users = await getUsers();
  return NextResponse.json(users);
}

export async function POST(request: NextRequest) {
  const body = await request.json();
  // Validate with Zod
  const parsed = createUserSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Validation failed", details: parsed.error.flatten() },
      { status: 400 }
    );
  }
  const user = await createUser(parsed.data);
  return NextResponse.json(user, { status: 201 });
}
```

## Key Rules

1. **Named exports** — `GET`, `POST`, `PUT`, `DELETE`, `PATCH` (uppercase)
2. **Validate all input** — Use Zod for request body validation
3. **Consistent error format** — `{ error: string, details?: object }`
4. **Status codes** — 200 (OK), 201 (Created), 400 (Bad Request), 401 (Unauthorized), 404 (Not Found), 500 (Server Error)

## Checklist

- [ ] Request body validated with Zod schema
- [ ] Error responses follow `{ error, details }` format
- [ ] Correct HTTP status codes
- [ ] Auth checks where required
- [ ] No server secrets exposed in response
```

- [ ] **Step 5: Validate and commit**

Run: `bash tests/validate-pack.sh forge/packs/nextjs`
Expected: `=== PASS: nextjs is valid ===`

```bash
cd /Users/timcollins/forge-framework
git add forge/packs/nextjs/
git commit -m "feat: add nextjs pack (app-router, server-components, api-routes)"
```

---

## Phase 4: Stack Packs

### Task 11: React Pack

**Files:**
- Create: `forge/packs/react/pack.yaml`
- Create: `forge/packs/react/skills/component-patterns/SKILL.md`
- Create: `forge/packs/react/skills/hooks/SKILL.md`

- [ ] **Step 1: Write pack.yaml**

Create `forge/packs/react/pack.yaml`:

```yaml
name: react
description: React component patterns, hooks, state management, and performance
detect:
  deps: ["react"]
  dirs: ["src/components/"]
roles: [engineer, designer]
```

- [ ] **Step 2: Write component-patterns skill**

Create `forge/packs/react/skills/component-patterns/SKILL.md`:

```markdown
---
name: react:component-patterns
description: React component best practices — composition, prop patterns, render optimization
trigger: |
  - Creating new React components
  - Component refactoring
  - Performance issues with re-renders
skip_when: |
  - Non-React project
---

# Component Patterns

## Key Rules

1. **Composition over configuration** — Pass children/render props instead of boolean flags
2. **Single responsibility** — One component, one job
3. **Colocation** — Keep styles, tests, and types next to the component
4. **Memoize expensive renders** — `React.memo` for pure display components, `useMemo` for expensive computations

## Patterns

### Compound Components
```tsx
// Instead of <Select options={[...]} onChange={...} renderOption={...} />
<Select value={selected} onChange={setSelected}>
  <Select.Trigger>{selected}</Select.Trigger>
  <Select.Options>
    <Select.Option value="a">Option A</Select.Option>
    <Select.Option value="b">Option B</Select.Option>
  </Select.Options>
</Select>
```

### Render Props vs Hooks
```tsx
// Prefer hooks for logic reuse
function useClickOutside(ref: RefObject<HTMLElement>, handler: () => void) {
  useEffect(() => {
    const listener = (e: MouseEvent) => {
      if (!ref.current?.contains(e.target as Node)) handler();
    };
    document.addEventListener("mousedown", listener);
    return () => document.removeEventListener("mousedown", listener);
  }, [ref, handler]);
}
```

## Checklist

- [ ] Components have single responsibility
- [ ] No prop drilling beyond 2 levels (use context or composition)
- [ ] Expensive renders memoized
- [ ] Event handlers use `useCallback` when passed as props to memoized children
```

- [ ] **Step 3: Write hooks skill**

Create `forge/packs/react/skills/hooks/SKILL.md`:

```markdown
---
name: react:hooks
description: Custom React hook patterns — data fetching, state management, side effects
trigger: |
  - Writing custom hooks
  - Hook dependency array issues
  - State management decisions
skip_when: |
  - Server Components (no hooks allowed)
---

# Custom Hook Patterns

## Rules

1. **Prefix with `use`** — `useAuth`, `useForm`, `useLoadingState`
2. **Return stable references** — Memoize callbacks and objects
3. **Dependency arrays** — Include everything the effect reads. Lint with `react-hooks/exhaustive-deps`.
4. **Cleanup** — Every subscription needs a cleanup function

## Patterns

### Data Fetching Hook
```tsx
function useQuery<T>(url: string) {
  const [data, setData] = useState<T | null>(null);
  const [error, setError] = useState<Error | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const controller = new AbortController();
    fetch(url, { signal: controller.signal })
      .then((res) => res.json())
      .then(setData)
      .catch((err) => {
        if (err.name !== "AbortError") setError(err);
      })
      .finally(() => setLoading(false));
    return () => controller.abort();
  }, [url]);

  return { data, error, loading };
}
```

## Checklist

- [ ] Custom hooks start with `use`
- [ ] Effects clean up subscriptions/timers
- [ ] Dependency arrays are complete (no lint suppressions)
- [ ] Returned objects/callbacks are stable (memoized)
```

- [ ] **Step 4: Validate and commit**

Run: `bash tests/validate-pack.sh forge/packs/react`

```bash
cd /Users/timcollins/forge-framework
git add forge/packs/react/
git commit -m "feat: add react pack (component-patterns, hooks)"
```

---

### Task 12: Supabase Pack

**Files:**
- Create: `forge/packs/supabase/pack.yaml`
- Create: `forge/packs/supabase/skills/schema-design/SKILL.md`
- Create: `forge/packs/supabase/skills/rls-policies/SKILL.md`

- [ ] **Step 1: Write pack.yaml**

Create `forge/packs/supabase/pack.yaml`:

```yaml
name: supabase
description: Supabase database patterns, RLS policies, migrations, and auth
detect:
  files: ["supabase/config.toml"]
  deps: ["@supabase/supabase-js"]
  dirs: ["supabase/migrations/"]
roles: [engineer]
```

- [ ] **Step 2: Write schema-design skill**

Create `forge/packs/supabase/skills/schema-design/SKILL.md`:

```markdown
---
name: supabase:schema-design
description: PostgreSQL/Supabase schema patterns — tables, relationships, migrations
trigger: |
  - Creating new database tables
  - Writing migrations
  - Schema design decisions
skip_when: |
  - No Supabase in project
---

# Schema Design

## Key Rules

1. **JOINs over duplication** — If data exists in another table, JOIN to it
2. **FK to lookup tables** — Use foreign keys, not string columns for categories
3. **Minimal migrations** — Prefer reusing existing columns over adding new ones
4. **Test locally first** — Always `npx supabase db reset` before committing migrations

## Migration Pattern

```sql
-- supabase/migrations/YYYYMMDDHHMMSS_description.sql
-- Always include both UP logic (no DOWN needed with Supabase)

ALTER TABLE companies ADD COLUMN IF NOT EXISTS status text DEFAULT 'active';
CREATE INDEX IF NOT EXISTS idx_companies_status ON companies(status);
```

## Checklist

- [ ] No duplicate data across tables (use JOINs)
- [ ] Foreign keys for all relationships
- [ ] Indexes on frequently queried columns
- [ ] Migration tested with `npx supabase db reset`
```

- [ ] **Step 3: Write rls-policies skill**

Create `forge/packs/supabase/skills/rls-policies/SKILL.md`:

```markdown
---
name: supabase:rls-policies
description: Row-Level Security patterns — policies, service role bypass, multi-tenant isolation
trigger: |
  - Creating new tables (RLS required)
  - Permission or access control issues
  - Multi-tenant data isolation
skip_when: |
  - Table is internal/system only (no user access)
---

# Row-Level Security

## Key Rules

1. **RLS on every user-facing table** — `ALTER TABLE t ENABLE ROW LEVEL SECURITY;`
2. **Service role bypasses RLS** — Use only server-side, never expose to client
3. **Separate policies per operation** — SELECT, INSERT, UPDATE, DELETE each get their own policy
4. **Test with anon/authenticated roles** — Not just service role

## Pattern

```sql
-- Enable RLS
ALTER TABLE assessments ENABLE ROW LEVEL SECURITY;

-- Users see only their own data
CREATE POLICY "users_select_own" ON assessments
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can only insert their own data
CREATE POLICY "users_insert_own" ON assessments
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);
```

## Checklist

- [ ] RLS enabled on all user-facing tables
- [ ] Separate policies for SELECT, INSERT, UPDATE, DELETE
- [ ] Service role key never exposed to client
- [ ] Policies tested with non-admin user
```

- [ ] **Step 4: Validate and commit**

Run: `bash tests/validate-pack.sh forge/packs/supabase`

```bash
cd /Users/timcollins/forge-framework
git add forge/packs/supabase/
git commit -m "feat: add supabase pack (schema-design, rls-policies)"
```

---

### Task 13: Tailwind Pack

**Files:**
- Create: `forge/packs/tailwind/pack.yaml`
- Create: `forge/packs/tailwind/skills/utility-patterns/SKILL.md`

- [ ] **Step 1: Write pack.yaml and skill**

Create `forge/packs/tailwind/pack.yaml`:

```yaml
name: tailwind
description: Tailwind CSS utility patterns and configuration
detect:
  files: ["tailwind.config.*"]
  deps: ["tailwindcss"]
roles: [engineer, designer]
```

Create `forge/packs/tailwind/skills/utility-patterns/SKILL.md`:

```markdown
---
name: tailwind:utility-patterns
description: Tailwind CSS patterns — responsive design, dark mode, custom utilities
trigger: |
  - Styling components with Tailwind
  - Responsive layout implementation
  - Custom theme configuration
skip_when: |
  - CSS modules or styled-components project
---

# Tailwind Utility Patterns

## Key Rules

1. **Mobile-first** — Default styles are mobile, add `md:`, `lg:` for larger screens
2. **Component extraction** — Repeating utility groups → extract to component, not `@apply`
3. **Design tokens** — Use theme values (`text-primary`) not arbitrary values (`text-[#1a2b3c]`)
4. **Dark mode** — Use `dark:` variant, configured via `class` strategy

## Responsive Pattern

```tsx
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
  {items.map(item => <Card key={item.id} {...item} />)}
</div>
```

## Checklist

- [ ] No arbitrary values when theme token exists
- [ ] Responsive breakpoints mobile-first
- [ ] Repeated utility groups extracted to components
```

- [ ] **Step 2: Validate and commit**

Run: `bash tests/validate-pack.sh forge/packs/tailwind`

```bash
cd /Users/timcollins/forge-framework
git add forge/packs/tailwind/
git commit -m "feat: add tailwind pack"
```

---

### Task 14: Golang Pack

**Files:**
- Create: `forge/packs/golang/pack.yaml`
- Create: `forge/packs/golang/skills/error-handling/SKILL.md`
- Create: `forge/packs/golang/skills/concurrency/SKILL.md`

- [ ] **Step 1: Write pack.yaml**

Create `forge/packs/golang/pack.yaml`:

```yaml
name: golang
description: Go idioms, error handling, concurrency, and testing patterns
detect:
  files: ["go.mod"]
roles: [engineer]
```

- [ ] **Step 2: Write error-handling skill**

Create `forge/packs/golang/skills/error-handling/SKILL.md`:

```markdown
---
name: golang:error-handling
description: Go error handling — wrapping, sentinel errors, custom types, error chains
trigger: |
  - Writing functions that can fail
  - Error handling patterns
  - Custom error type creation
skip_when: |
  - Non-Go code
---

# Go Error Handling

## Key Rules

1. **Always check errors** — Never `_ = err`
2. **Wrap with context** — `fmt.Errorf("loading user %s: %w", id, err)`
3. **Sentinel errors for callers** — `var ErrNotFound = errors.New("not found")`
4. **Check with `errors.Is`** — Not string comparison

## Patterns

```go
// Wrap errors with context
func GetUser(ctx context.Context, id string) (*User, error) {
    user, err := db.QueryUser(ctx, id)
    if err != nil {
        return nil, fmt.Errorf("getting user %s: %w", id, err)
    }
    return user, nil
}

// Sentinel errors
var ErrNotFound = errors.New("not found")

// Check errors
if errors.Is(err, ErrNotFound) {
    return http.StatusNotFound
}
```

## Checklist

- [ ] Every error is checked (no `_ = err`)
- [ ] Errors wrapped with `%w` and context
- [ ] Sentinel errors defined for API boundaries
- [ ] `errors.Is` / `errors.As` for checking (not string matching)
```

- [ ] **Step 3: Write concurrency skill**

Create `forge/packs/golang/skills/concurrency/SKILL.md`:

```markdown
---
name: golang:concurrency
description: Go concurrency — goroutines, channels, sync primitives, context cancellation
trigger: |
  - Writing concurrent code
  - Goroutine or channel usage
  - Context cancellation patterns
skip_when: |
  - Sequential code with no concurrency needs
---

# Go Concurrency

## Key Rules

1. **Always pass context** — Goroutines must respect `ctx.Done()`
2. **Bounded goroutines** — Use semaphores or worker pools, never unbounded `go func()`
3. **Close channels from sender** — Never close from receiver side
4. **`sync.WaitGroup` for fan-out** — Track goroutine completion

## Patterns

```go
// Worker pool with bounded concurrency
func process(ctx context.Context, items []Item, workers int) error {
    g, ctx := errgroup.WithContext(ctx)
    g.SetLimit(workers)
    for _, item := range items {
        g.Go(func() error {
            return processItem(ctx, item)
        })
    }
    return g.Wait()
}
```

## Checklist

- [ ] Goroutines check `ctx.Done()`
- [ ] Goroutine count bounded (worker pool or semaphore)
- [ ] No goroutine leaks (all paths terminate)
- [ ] Shared state protected by mutex or channels
```

- [ ] **Step 4: Validate and commit**

Run: `bash tests/validate-pack.sh forge/packs/golang`

```bash
cd /Users/timcollins/forge-framework
git add forge/packs/golang/
git commit -m "feat: add golang pack (error-handling, concurrency)"
```

---

### Task 15: Python Pack

**Files:**
- Create: `forge/packs/python/pack.yaml`
- Create: `forge/packs/python/skills/pythonic-patterns/SKILL.md`

- [ ] **Step 1: Write pack.yaml and skill**

Create `forge/packs/python/pack.yaml`:

```yaml
name: python
description: Python idioms, type hints, testing, and project structure
detect:
  files: ["pyproject.toml", "requirements.txt", "setup.py"]
roles: [engineer]
```

Create `forge/packs/python/skills/pythonic-patterns/SKILL.md`:

```markdown
---
name: python:pythonic-patterns
description: Pythonic idioms — type hints, comprehensions, context managers, dataclasses
trigger: |
  - Writing Python code
  - Python project setup
  - Type hint questions
skip_when: |
  - Non-Python code
---

# Pythonic Patterns

## Key Rules

1. **Type hints everywhere** — All function signatures, class attributes
2. **Dataclasses over dicts** — Structured data gets a dataclass
3. **Context managers** — Resources that need cleanup use `with`
4. **Comprehensions** — Prefer over `map`/`filter` for readability

## Patterns

```python
from dataclasses import dataclass

@dataclass
class User:
    id: str
    email: str
    role: str = "viewer"

def get_active_users(users: list[User]) -> list[User]:
    return [u for u in users if u.role != "inactive"]
```

## Checklist

- [ ] All functions have type hints (params and return)
- [ ] Structured data uses dataclasses (not raw dicts)
- [ ] File/DB operations use context managers
- [ ] No bare `except:` — always specify exception type
```

- [ ] **Step 2: Validate and commit**

Run: `bash tests/validate-pack.sh forge/packs/python`

```bash
cd /Users/timcollins/forge-framework
git add forge/packs/python/
git commit -m "feat: add python pack"
```

---

### Task 16: Docker Pack

**Files:**
- Create: `forge/packs/docker/pack.yaml`
- Create: `forge/packs/docker/skills/dockerfile-patterns/SKILL.md`

- [ ] **Step 1: Write pack.yaml and skill**

Create `forge/packs/docker/pack.yaml`:

```yaml
name: docker
description: Docker and Docker Compose patterns for development and production
detect:
  files: ["Dockerfile", "docker-compose.*"]
roles: [engineer]
```

Create `forge/packs/docker/skills/dockerfile-patterns/SKILL.md`:

```markdown
---
name: docker:dockerfile-patterns
description: Dockerfile best practices — multi-stage builds, layer caching, security
trigger: |
  - Creating or modifying Dockerfiles
  - Docker build optimization
  - Container security questions
skip_when: |
  - No Docker in project
---

# Dockerfile Patterns

## Key Rules

1. **Multi-stage builds** — Separate build and runtime stages
2. **Non-root user** — Run as non-root in production
3. **Layer caching** — Copy dependency files before source code
4. **`.dockerignore`** — Exclude node_modules, .git, .env

## Pattern

```dockerfile
# Build stage
FROM node:22-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

# Runtime stage
FROM node:22-alpine AS runner
WORKDIR /app
RUN addgroup -g 1001 -S app && adduser -S app -u 1001
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./
USER app
EXPOSE 3000
CMD ["npm", "start"]
```

## Checklist

- [ ] Multi-stage build (build ≠ runtime)
- [ ] Non-root user in runtime stage
- [ ] .dockerignore excludes node_modules, .git, .env
- [ ] Dependency install before source copy (layer caching)
```

- [ ] **Step 2: Validate and commit**

Run: `bash tests/validate-pack.sh forge/packs/docker`

```bash
cd /Users/timcollins/forge-framework
git add forge/packs/docker/
git commit -m "feat: add docker pack"
```

---

### Task 17: Run Full Validation

- [ ] **Step 1: Validate all packs**

```bash
cd /Users/timcollins/forge-framework
for pack in forge/packs/*/; do
  bash tests/validate-pack.sh "$pack"
  echo ""
done
```

Expected: All packs PASS.

- [ ] **Step 2: Run detection tests**

Run: `bash tests/test-detection.sh`
Expected: All tests PASS.

---

## Phase 5: Domain Packs

### Task 18: Healthcare Pack (Opt-In)

**Files:**
- Create: `forge/packs/healthcare/pack.yaml`
- Create: `forge/packs/healthcare/skills/llm-safety/SKILL.md`
- Create: `forge/packs/healthcare/skills/phi-compliance/SKILL.md`

- [ ] **Step 1: Write pack.yaml**

Create `forge/packs/healthcare/pack.yaml`:

```yaml
name: healthcare
description: Healthcare compliance, LLM safety, PHI handling, and clinical patterns
roles: [engineer]
# No detect rules — opt-in via extra_packs in forge.yaml
```

- [ ] **Step 2: Write llm-safety skill**

Create `forge/packs/healthcare/skills/llm-safety/SKILL.md`:

```markdown
---
name: healthcare:llm-safety
description: LLM safety standards for healthcare — prompt guards, score validation, content labeling
trigger: |
  - Creating or modifying LLM prompts
  - AI-generated content in healthcare context
  - Score or classification from LLM output
skip_when: |
  - No LLM calls in the feature
---

# LLM Safety Standards

## Classification

| Type | Use Case | Temperature |
|------|----------|-------------|
| A | RAG Extraction | 0.1 |
| B | Evaluation & Scoring | 0.1 |
| C | Chat/Assistant | 0.2-0.3 |
| D | Content Generation | 0.3 |

## Every Prompt MUST Include

1. **No Fabrication** — "Do not fabricate information. If uncertain, say so."
2. **Uncertainty** — "Express confidence levels. Never state uncertain facts as definitive."
3. **Output Boundary** — "Only output the requested format. No additional commentary."

## Untrusted Data

Wrap ALL external content with markers:

```
<<<UNTRUSTED_VENDOR_DOC_START>>>
{vendor document content}
<<<UNTRUSTED_VENDOR_DOC_END>>>
```

## Score Validation

- **Never trust raw LLM scores** — Always clamp server-side
- Not-found answers MUST score <= 0.3
- All scores validated against expected ranges

## UI Labeling

- AI-generated content marked with indicator icon in UI
- Database flag: `ai_generated: true`

## Checklist

- [ ] Prompt includes No Fabrication + Uncertainty + Output Boundary clauses
- [ ] Untrusted data wrapped with markers
- [ ] Scores validated/clamped server-side
- [ ] AI-generated content labeled in UI and DB
- [ ] Temperature set per classification type
```

- [ ] **Step 3: Write phi-compliance skill**

Create `forge/packs/healthcare/skills/phi-compliance/SKILL.md`:

```markdown
---
name: healthcare:phi-compliance
description: PHI handling — HIPAA compliance, data minimization, audit logging
trigger: |
  - Handling patient data or PII
  - Logging that might include PHI
  - API responses containing user health data
skip_when: |
  - No health data in the feature
---

# PHI Compliance

## Key Rules

1. **Minimize PHI exposure** — Only fetch/display the minimum fields needed
2. **Never log PHI** — Redact before logging. Log IDs, not names/emails.
3. **Encrypt at rest and in transit** — TLS for transit, AES-256 for storage
4. **Audit trail** — All PHI access must be logged (who, what, when)

## Logging Pattern

```typescript
// WRONG — logs PHI
console.log("Processing patient:", patient.name, patient.ssn);

// RIGHT — logs only IDs
console.log("Processing patient:", patient.id);
```

## Checklist

- [ ] No PHI in console.log, error messages, or analytics
- [ ] API responses return minimum required fields
- [ ] PHI access logged to audit table (user_id, resource, action, timestamp)
- [ ] Data encrypted at rest (Supabase handles this by default)
```

- [ ] **Step 4: Validate and commit**

Run: `bash tests/validate-pack.sh forge/packs/healthcare`

```bash
cd /Users/timcollins/forge-framework
git add forge/packs/healthcare/
git commit -m "feat: add healthcare pack (llm-safety, phi-compliance)"
```

---

### Task 19: Planning Pack (Opt-In)

**Files:**
- Create: `forge/packs/planning/pack.yaml`
- Create: `forge/packs/planning/skills/brainstorming/SKILL.md`
- Create: `forge/packs/planning/skills/writing-plans/SKILL.md`

- [ ] **Step 1: Write pack.yaml**

Create `forge/packs/planning/pack.yaml`:

```yaml
name: planning
description: Brainstorming, design specs, implementation planning, and task breakdown
roles: [engineer, pm]
# No detect rules — opt-in via extra_packs
```

- [ ] **Step 2: Write brainstorming skill**

Create `forge/packs/planning/skills/brainstorming/SKILL.md`:

```markdown
---
name: planning:brainstorming
description: Socratic design refinement — ideas to validated designs through structured questioning
trigger: |
  - New feature or product idea
  - User says "plan", "design", or "architect"
  - Multiple approaches possible, design unclear
skip_when: |
  - Design already complete → use planning:writing-plans
  - Have detailed plan ready → execute directly
---

# Brainstorming

## Process

1. **Explore context** — Check repo, docs, recent commits
2. **Ask clarifying questions** — One at a time, prefer multiple choice
3. **Propose 2-3 approaches** — With trade-offs and recommendation
4. **Present design** — Section by section, get approval after each
5. **Write design doc** — Save to `docs/specs/YYYY-MM-DD-<topic>-design.md`
6. **Self-review** — Check for placeholders, contradictions, ambiguity
7. **Handoff** — Invoke planning:writing-plans for implementation plan

## Key Rules

- One question at a time
- YAGNI ruthlessly — remove unnecessary features
- Present design before writing any code
- Scale each section to its complexity
```

- [ ] **Step 3: Write writing-plans skill**

Create `forge/packs/planning/skills/writing-plans/SKILL.md`:

```markdown
---
name: planning:writing-plans
description: Implementation plan creation — bite-sized tasks, TDD, exact file paths
trigger: |
  - Approved design spec needs implementation plan
  - Feature breakdown requested
  - "Write a plan" or "create an implementation plan"
skip_when: |
  - No design spec exists → use planning:brainstorming first
---

# Writing Plans

## Task Granularity

Each step is one action (2-5 minutes):
- "Write the failing test" — step
- "Run it to make sure it fails" — step
- "Implement minimal code" — step
- "Run tests, make sure they pass" — step
- "Commit" — step

## Required Content

- Exact file paths for every change
- Complete code in every step
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits

## Plan Structure

```markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file`
- Modify: `exact/path/to/existing:lines`
- Test: `tests/path/to/test`

- [ ] Step 1: Write failing test
- [ ] Step 2: Run test (expect FAIL)
- [ ] Step 3: Write implementation
- [ ] Step 4: Run test (expect PASS)
- [ ] Step 5: Commit
```

## No Placeholders

Never write: "TBD", "TODO", "implement later", "add appropriate error handling", "similar to Task N".
```

- [ ] **Step 4: Validate and commit**

Run: `bash tests/validate-pack.sh forge/packs/planning`

```bash
cd /Users/timcollins/forge-framework
git add forge/packs/planning/
git commit -m "feat: add planning pack (brainstorming, writing-plans)"
```

---

### Task 20: Leadership Pack (Opt-In)

**Files:**
- Create: `forge/packs/leadership/pack.yaml`
- Create: `forge/packs/leadership/skills/architecture-decisions/SKILL.md`
- Create: `forge/packs/leadership/skills/sprint-planning/SKILL.md`

- [ ] **Step 1: Write pack.yaml and skills**

Create `forge/packs/leadership/pack.yaml`:

```yaml
name: leadership
description: CTO/engineering leadership — architecture decisions, sprint planning, tech debt, hiring
roles: [engineer, pm]
# No detect rules — opt-in via extra_packs
```

Create `forge/packs/leadership/skills/architecture-decisions/SKILL.md`:

```markdown
---
name: leadership:architecture-decisions
description: Architecture Decision Records — structured decision making with trade-off analysis
trigger: |
  - Major technical decision needed
  - "ADR", "architecture decision", "build vs buy"
  - Technology selection or migration planning
skip_when: |
  - Implementation details (not architectural level)
---

# Architecture Decision Records

## Format

```markdown
# ADR-NNN: [Title]

**Status:** Proposed | Accepted | Deprecated | Superseded
**Date:** YYYY-MM-DD
**Deciders:** [Names]

## Context
What is the issue? Why does this decision need to be made?

## Decision
What was decided? Be specific.

## Consequences
### Positive
- Benefit 1
### Negative
- Trade-off 1
### Risks
- Risk 1 and mitigation
```

## Checklist

- [ ] Context explains the problem, not the solution
- [ ] At least 2 alternatives evaluated
- [ ] Trade-offs explicit (not just positives)
- [ ] Risks identified with mitigations
```

Create `forge/packs/leadership/skills/sprint-planning/SKILL.md`:

```markdown
---
name: leadership:sprint-planning
description: Sprint planning — estimation, capacity, scope negotiation
trigger: |
  - Sprint planning session
  - Estimation or sizing discussion
  - Scope negotiation needed
skip_when: |
  - Individual task execution (not planning)
---

# Sprint Planning

## Process

1. **Review backlog** — Prioritized by product, sized by engineering
2. **Capacity check** — Team availability minus meetings, on-call, PTO
3. **Scope to capacity** — Pull items until capacity filled at 70% (buffer for unknowns)
4. **Identify dependencies** — Flag cross-team blockers early

## Estimation Rules

- Use relative sizing (S/M/L/XL), not hours
- S = < 2 hours, M = half day, L = 1-2 days, XL = 3-5 days (break down further)
- If XL, it should be decomposed into smaller items
- Include testing and review time in estimates

## Checklist

- [ ] Backlog prioritized before planning
- [ ] Capacity calculated (available hours - overhead)
- [ ] Sprint filled to 70% capacity
- [ ] Dependencies identified and owners assigned
- [ ] Each item has acceptance criteria
```

- [ ] **Step 2: Validate and commit**

Run: `bash tests/validate-pack.sh forge/packs/leadership`

```bash
cd /Users/timcollins/forge-framework
git add forge/packs/leadership/
git commit -m "feat: add leadership pack (architecture-decisions, sprint-planning)"
```

---

### Task 21: Writing Pack (Opt-In)

**Files:**
- Create: `forge/packs/writing/pack.yaml`
- Create: `forge/packs/writing/skills/technical-docs/SKILL.md`

- [ ] **Step 1: Write pack.yaml and skill**

Create `forge/packs/writing/pack.yaml`:

```yaml
name: writing
description: Technical writing — documentation structure, API docs, guides
roles: [engineer, pm, designer]
# No detect rules — opt-in via extra_packs
```

Create `forge/packs/writing/skills/technical-docs/SKILL.md`:

```markdown
---
name: writing:technical-docs
description: Technical documentation patterns — structure, voice, completeness
trigger: |
  - Writing documentation
  - README, guide, or tutorial creation
  - API documentation
skip_when: |
  - Code comments only (not standalone docs)
---

# Technical Documentation

## Structure

1. **Title** — What this is
2. **One-line summary** — What it does and who it's for
3. **Quick start** — Fastest path to working
4. **Concepts** — Mental model (only if non-obvious)
5. **Reference** — Complete API/config details
6. **Troubleshooting** — Common problems and solutions

## Voice Rules

- Active voice, present tense
- "You" not "the user"
- Commands, not suggestions ("Run X" not "You might want to run X")
- Show, don't tell (code examples over prose)

## Checklist

- [ ] Title and one-line summary present
- [ ] Quick start gets reader to working state in < 5 steps
- [ ] Code examples are copy-pasteable (complete, not fragments)
- [ ] No jargon without definition on first use
```

- [ ] **Step 2: Validate and commit**

Run: `bash tests/validate-pack.sh forge/packs/writing`

```bash
cd /Users/timcollins/forge-framework
git add forge/packs/writing/
git commit -m "feat: add writing pack (technical-docs)"
```

---

## Phase 6: Commands

### Task 22: `/forge init` Command

**Files:**
- Create: `forge/commands/forge-init.md`

- [ ] **Step 1: Write forge-init.md**

Create `forge/commands/forge-init.md`:

```markdown
---
name: forge:init
description: Bootstrap .forge/ directory in an existing repo with team knowledge, role configs, and auto-detected packs
argument-hint: "[--template <name>]"
---

# /forge init

Bootstrap the `.forge/` directory in the current repository.

## What It Does

1. **Detect stack** — Runs detection engine, shows proposed packs
2. **Extract knowledge** — Reads existing CLAUDE.md, classifies content into decisions, conventions, gotchas
3. **Import memories** — Scans `~/.claude/projects/.../memory/` for team-relevant entries, proposes promoting them to shared knowledge
4. **Scaffold** — Creates `.forge/` directory with:
   - `forge.yaml` — project configuration with detected packs
   - `knowledge/INDEX.md` — manifest of all knowledge entries
   - `knowledge/decisions/` — extracted decision files
   - `knowledge/conventions/` — extracted convention files
   - `knowledge/gotchas/` — extracted gotcha files
   - `roles/engineer.yaml` — default engineer role config
   - `roles/pm.yaml` — default PM role config
   - `roles/designer.yaml` — default designer role config
   - `roles/agent.yaml` — default agent role config
   - `eval/` — empty eval directory
5. **Generate lean CLAUDE.md** — Replaces bloated CLAUDE.md with ~500 token version pointing to `.forge/`

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `--template <name>` | No | Use a template repo for org-wide defaults |

## Process

The init command is interactive. It will:
- Show detected packs and ask for confirmation
- Show extracted knowledge and ask which to keep
- Show memory entries and ask which to promote
- Preview the lean CLAUDE.md before writing

## Implementation

When this command is invoked:

1. Run `${CLAUDE_PLUGIN_ROOT}/core/detection.sh` to detect packs
2. Read existing CLAUDE.md (if present)
3. Use an LLM call to classify CLAUDE.md sections into decision/convention/gotcha
4. Read `~/.claude/projects/*/memory/*.md` files
5. For each memory file, check if `type` is `user` (personal, skip) or other (propose promotion)
6. Create `.forge/` directory structure
7. Write all files
8. Generate INDEX.md from knowledge file summaries
9. Generate lean CLAUDE.md
10. Suggest adding `.forge/eval/usage.jsonl` to `.gitignore`
```

- [ ] **Step 2: Commit**

```bash
cd /Users/timcollins/forge-framework
git add forge/commands/forge-init.md
git commit -m "feat: add /forge init command"
```

---

### Task 23: `/forge role` Command

**Files:**
- Create: `forge/commands/forge-role.md`

- [ ] **Step 1: Write forge-role.md**

Create `forge/commands/forge-role.md`:

```markdown
---
name: forge:role
description: Set your role for gate enforcement (engineer, pm, designer, agent)
argument-hint: "<role>"
---

# /forge role

Set your active role. This determines which gates are enforced in your sessions.

## Usage

```
/forge role engineer    # Full gates
/forge role pm          # Planning + knowledge gates
/forge role designer    # Design + accessibility gates
/forge role agent       # Critical path only
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `role` | Yes | One of: `engineer`, `pm`, `designer`, `agent` |

## Implementation

When invoked:
1. Validate role is one of the allowed values
2. Write role to `~/.claude/forge-role`
3. Confirm: "Role set to {role}. Gates will apply on next session start."

## What Changes Per Role

| Gate | engineer | pm | designer | agent |
|------|----------|-----|----------|-------|
| 3-file rule | Yes | No | No | Yes |
| Skill check | Yes | Yes | Yes | No |
| Knowledge gate | Yes | Yes | Yes | Yes |
| Dev cycle | Yes | No | No | No |
| Build verification | Yes | No | No | Yes |
```

- [ ] **Step 2: Commit**

```bash
cd /Users/timcollins/forge-framework
git add forge/commands/forge-role.md
git commit -m "feat: add /forge role command"
```

---

### Task 24: `/forge eval` Command

**Files:**
- Create: `forge/commands/forge-eval.md`

- [ ] **Step 1: Write forge-eval.md**

Create `forge/commands/forge-eval.md`:

```markdown
---
name: forge:eval
description: Run skill quality evaluation — scores skills, produces report, recommends actions
argument-hint: ""
---

# /forge eval

Analyze skill usage data and produce a quality report.

## Usage

```
/forge eval
```

## What It Does

1. **Read usage data** — Parse `.forge/eval/usage.jsonl`
2. **Score each skill** — Calculate scores across 5 dimensions:
   - Adoption (0-25): frequency and natural discovery
   - Completion (0-25): follow-through rate
   - Impact (0-25): prevented known mistakes
   - Efficiency (0-15): turns added to session
   - Cross-Role (0-10): useful across roles
3. **Assign tiers** — Bronze (40-59), Silver (60-79), Gold (80-89), Platinum (90+)
4. **Generate report** — Write to `.forge/eval/reports/YYYY-MM-DD.md`
5. **Update scores** — Write to `.forge/eval/scores.json`
6. **Prune old data** — Roll up usage entries older than 30 days

## Implementation

When invoked:
1. Check `.forge/eval/usage.jsonl` exists and has entries
2. Dispatch the `forge:scorer` agent to analyze the data
3. The scorer agent reads usage.jsonl, calculates scores, and writes:
   - `scores.json` — updated skill scores
   - `reports/YYYY-MM-DD.md` — human-readable report
4. Suggest committing the results

## Report Format

```markdown
# Forge Eval Report — YYYY-MM-DD

## Summary
- Skills evaluated: N
- Platinum: N | Gold: N | Silver: N | Bronze: N

## Recommendations
- **Prune:** [skill] — 0 invocations in 30 days
- **Promote:** [skill] — Gold tier, consider for core
- **Revise:** [skill] — High override rate (N%), investigate why

## Skill Scores
| Skill | Score | Tier | Adoption | Completion | Impact | Efficiency | Cross-Role |
```
```

- [ ] **Step 2: Commit**

```bash
cd /Users/timcollins/forge-framework
git add forge/commands/forge-eval.md
git commit -m "feat: add /forge eval command"
```

---

## Phase 7: Eval System

### Task 25: Telemetry Hook

**Files:**
- Create: `forge/eval/telemetry.sh`

- [ ] **Step 1: Write telemetry.sh**

Create `forge/eval/telemetry.sh`:

```bash
#!/usr/bin/env bash
# Forge Telemetry — appends skill usage data to .forge/eval/usage.jsonl
# Called by skills/orchestrator with: telemetry.sh <skill> <outcome> <role> [override_reason]
set -euo pipefail

REPO_ROOT="$(pwd)"
USAGE_FILE="$REPO_ROOT/.forge/eval/usage.jsonl"

SKILL="${1:-unknown}"
OUTCOME="${2:-unknown}"
ROLE="${3:-engineer}"
OVERRIDE_REASON="${4:-}"
DATE=$(date -u +"%Y-%m-%d")
SESSION="${CLAUDE_SESSION_ID:-$(date +%s)}"

# Create eval directory if needed
mkdir -p "$(dirname "$USAGE_FILE")"

# Build JSON entry
if [ -n "$OVERRIDE_REASON" ]; then
  echo "{\"skill\":\"$SKILL\",\"outcome\":\"$OUTCOME\",\"date\":\"$DATE\",\"role\":\"$ROLE\",\"session\":\"$SESSION\",\"user_override\":true,\"override_reason\":\"$OVERRIDE_REASON\"}" >> "$USAGE_FILE"
else
  echo "{\"skill\":\"$SKILL\",\"outcome\":\"$OUTCOME\",\"date\":\"$DATE\",\"role\":\"$ROLE\",\"session\":\"$SESSION\",\"user_override\":false}" >> "$USAGE_FILE"
fi
```

- [ ] **Step 2: Make executable and test**

```bash
chmod +x forge/eval/telemetry.sh

# Test it
mkdir -p /tmp/forge-test/.forge/eval
cd /tmp/forge-test
/Users/timcollins/forge-framework/forge/eval/telemetry.sh "nextjs:app-router" "completed" "engineer"
cat .forge/eval/usage.jsonl
# Should show one JSON line with the skill invocation
rm -rf /tmp/forge-test
```

- [ ] **Step 3: Commit**

```bash
cd /Users/timcollins/forge-framework
git add forge/eval/telemetry.sh
git commit -m "feat: add telemetry hook for skill usage tracking"
```

---

### Task 26: Scorer Agent

**Files:**
- Create: `forge/eval/scorer.md`

- [ ] **Step 1: Write scorer.md**

Create `forge/eval/scorer.md`:

```markdown
---
name: forge:scorer
description: "Skill quality evaluation agent. Reads usage data, calculates scores, produces reports."
type: analyzer
tools: ["Read", "Write", "Bash", "Grep"]
---

# Forge Scorer

You are the skill quality evaluation agent. You analyze `.forge/eval/usage.jsonl` and produce skill scores and reports.

## Input

Read `.forge/eval/usage.jsonl` — one JSON object per line with fields:
- `skill`: skill identifier (e.g., "nextjs:app-router")
- `outcome`: "completed" | "overridden" | "skipped"
- `date`: ISO date
- `role`: user role
- `session`: session ID
- `user_override`: boolean
- `override_reason`: string (if overridden)

## Scoring Algorithm

For each skill with at least 1 entry:

### Adoption (0-25)
- 0 entries in 30 days: 0
- 1-4 entries: 5
- 5-19 entries: 15
- 20+ entries: 25

### Completion (0-25)
- completion_rate = completed / (completed + overridden)
- Score = completion_rate * 25

### Impact (0-25)
- Check if any entry has `prevented_mistake: true`
- 0 prevented: 5 (baseline)
- 1-2 prevented: 15
- 3+ prevented: 25

### Efficiency (0-15)
- avg_turns = average of `duration_turns` across completed entries
- <= 2 turns: 15
- 3-4 turns: 10
- 5-7 turns: 5
- 8+ turns: 0

### Cross-Role (0-10)
- Count distinct roles using the skill
- 1 role: 0
- 2 roles: 5
- 3+ roles: 10

### Total = Adoption + Completion + Impact + Efficiency + Cross-Role

### Tier Assignment
- 90+: Platinum
- 80-89: Gold
- 60-79: Silver
- 40-59: Bronze
- <40: Unranked (too few data points)

## Output

### scores.json

```json
{
  "generated": "2026-04-09",
  "skills": {
    "nextjs:app-router": {
      "score": 85,
      "tier": "gold",
      "adoption": 25,
      "completion": 20,
      "impact": 15,
      "efficiency": 15,
      "cross_role": 10,
      "invocations": 32,
      "completion_rate": 0.84
    }
  }
}
```

### reports/YYYY-MM-DD.md

Write a human-readable markdown report with:
1. Summary (total skills, tier distribution)
2. Recommendations (prune, promote, revise)
3. Full score table

## Cleanup

After scoring, remove entries from `usage.jsonl` older than 30 days.
```

- [ ] **Step 2: Commit**

```bash
cd /Users/timcollins/forge-framework
git add forge/eval/scorer.md
git commit -m "feat: add scorer agent for skill evaluation"
```

---

## Phase 8: Role Config Templates & Polish

### Task 27: Role Configuration Templates

**Files:**
- Create: `forge/templates/roles/engineer.yaml`
- Create: `forge/templates/roles/pm.yaml`
- Create: `forge/templates/roles/designer.yaml`
- Create: `forge/templates/roles/agent.yaml`

These are templates that `/forge init` copies into `.forge/roles/`.

- [ ] **Step 1: Write engineer.yaml**

Create `forge/templates/roles/engineer.yaml`:

```yaml
role: engineer
description: Full development gates — all disciplines enforced

gates:
  three_file_rule: true
  skill_check: true
  knowledge_gate: true
  dev_cycle: true
  pre_dev_planning: true
  code_review: true
  build_verification: true
  test_gate: true
  auto_triggers: true
  doubt_triggered_questions: true
  brainstorming: true
  visual_companion: true
  design_system: false
  accessibility_gates: false
```

- [ ] **Step 2: Write pm.yaml**

Create `forge/templates/roles/pm.yaml`:

```yaml
role: pm
description: Planning and knowledge gates — no build or code review enforcement

gates:
  three_file_rule: false
  skill_check: true
  knowledge_gate: true
  dev_cycle: false
  pre_dev_planning: true
  code_review: false
  build_verification: false
  test_gate: false
  auto_triggers: false
  doubt_triggered_questions: true
  brainstorming: true
  visual_companion: false
  design_system: false
  accessibility_gates: false
```

- [ ] **Step 3: Write designer.yaml**

Create `forge/templates/roles/designer.yaml`:

```yaml
role: designer
description: Design and accessibility gates — focused on UI/UX quality

gates:
  three_file_rule: false
  skill_check: true
  knowledge_gate: true
  dev_cycle: false
  pre_dev_planning: false
  code_review: false
  build_verification: false
  test_gate: false
  auto_triggers: false
  doubt_triggered_questions: false
  brainstorming: true
  visual_companion: true
  design_system: true
  accessibility_gates: true
```

- [ ] **Step 4: Write agent.yaml**

Create `forge/templates/roles/agent.yaml`:

```yaml
role: agent
description: Critical path only — automated agents and CI bots

gates:
  three_file_rule: true
  skill_check: false
  knowledge_gate: true
  dev_cycle: false
  pre_dev_planning: false
  code_review: false
  build_verification: true
  test_gate: true
  auto_triggers: true
  doubt_triggered_questions: false
  brainstorming: false
  visual_companion: false
  design_system: false
  accessibility_gates: false
```

- [ ] **Step 5: Commit**

```bash
cd /Users/timcollins/forge-framework
git add forge/templates/
git commit -m "feat: add role configuration templates"
```

---

### Task 28: CLAUDE.md for Forge Repo

**Files:**
- Modify: `/Users/timcollins/forge-framework/CLAUDE.md` (create)

- [ ] **Step 1: Write CLAUDE.md**

Create `CLAUDE.md` in the repo root:

```markdown
# CLAUDE.md

## What This Is

Forge is a Claude Code plugin. It contains markdown, YAML, JSON, and shell scripts — no compiled code.

## Structure

```
forge/                    # The plugin (installed via marketplace)
├── core/                 # Always-loaded orchestrator (~300 tokens)
├── agents/               # Shared agents (explorer, planner, reviewer)
├── packs/                # Domain packs (auto-detected or opt-in)
├── hooks/                # Session lifecycle hooks
├── commands/             # User-invokable commands (/forge init, etc.)
├── eval/                 # Self-improvement system
└── templates/            # Templates copied by /forge init

tests/                    # Validation scripts
docs/                     # Specs and plans
```

## Testing

```bash
# Validate all packs
for pack in forge/packs/*/; do bash tests/validate-pack.sh "$pack"; done

# Test detection engine
bash tests/test-detection.sh
```

## Adding a New Pack

1. Create `forge/packs/<name>/pack.yaml` with name, description, detect rules, roles
2. Create `forge/packs/<name>/skills/<skill-name>/SKILL.md` with frontmatter (name, description, trigger, skip_when)
3. Run `bash tests/validate-pack.sh forge/packs/<name>` to verify
4. Commit
```

- [ ] **Step 2: Commit**

```bash
cd /Users/timcollins/forge-framework
git add CLAUDE.md
git commit -m "docs: add CLAUDE.md for forge repo"
```

---

### Task 29: Final Validation & Push

- [ ] **Step 1: Validate all packs**

```bash
cd /Users/timcollins/forge-framework
for pack in forge/packs/*/; do
  echo "--- $(basename "$pack") ---"
  bash tests/validate-pack.sh "$pack"
  echo ""
done
```

Expected: All packs PASS.

- [ ] **Step 2: Run detection tests**

Run: `bash tests/test-detection.sh`
Expected: All tests PASS.

- [ ] **Step 3: Verify plugin.json is valid**

Run: `python3 -c "import json; j=json.load(open('forge/.claude-plugin/plugin.json')); print(f'Plugin: {j[\"name\"]} v{j[\"version\"]}')" `
Expected: `Plugin: forge v0.1.0`

- [ ] **Step 4: Check file count and structure**

```bash
echo "=== File counts ==="
echo "Packs: $(ls -d forge/packs/*/ | wc -l | tr -d ' ')"
echo "Skills: $(find forge/packs -name 'SKILL.md' | wc -l | tr -d ' ')"
echo "Agents: $(ls forge/agents/*.md | wc -l | tr -d ' ')"
echo "Commands: $(ls forge/commands/*.md | wc -l | tr -d ' ')"
echo "Core files: $(ls forge/core/* | wc -l | tr -d ' ')"
```

Expected:
- Packs: 10
- Skills: ~16
- Agents: 3
- Commands: 3
- Core files: 3

- [ ] **Step 5: Push to remote**

```bash
cd /Users/timcollins/forge-framework
git push origin main
```

---

## Summary

| Phase | Tasks | What It Delivers |
|-------|-------|-----------------|
| 1. Plugin Skeleton & Core | 1-4 | Working plugin structure, orchestrator, detection engine, pack loader |
| 2. Hooks & Agents | 5-7 | Session start hook, explorer/planner/reviewer agents |
| 3. First Pack + Validation | 8-10 | Pack validation script, TypeScript and Next.js packs |
| 4. Stack Packs | 11-17 | React, Supabase, Tailwind, Go, Python, Docker packs |
| 5. Domain Packs | 18-21 | Healthcare, Planning, Leadership, Writing packs |
| 6. Commands | 22-24 | /forge init, /forge role, /forge eval |
| 7. Eval System | 25-26 | Telemetry hook, scorer agent |
| 8. Templates & Polish | 27-29 | Role configs, CLAUDE.md, final validation |
