---
name: forge:orchestrator
description: |
  Core orchestrator for Forge. Enforces mandatory gates,
  progressive disclosure, and team knowledge integration.
---

# Forge Orchestrator

## Hard Gates (Enforced via `<gate-enforcement>` in session context)

Gates are injected by the session-start hook based on the role config. When a `<gate>` tag is present in your session context with `enforced="true"`, you MUST obey it. These are not suggestions.

### Start Gates (before implementation)
1. **Brainstorming** — For new features/projects, complete the full brainstorming flow BEFORE writing code.
2. **Pre-Dev Planning** — For 2+ day features, complete research/PRD/TRD first.
3. **Knowledge First** — Check `.forge/knowledge/INDEX.md` before making assumptions.
4. **Skill Check** — Before any action, check if an active pack skill matches. If yes, invoke it.

### During Gates (while implementing)
5. **3-File Rule** — Touched >3 files? STOP. Dispatch agent. No exceptions.

### Completion Gates (before handoff)
6. **Completion Checklist** — You MUST NOT say "done" until you have:
   - **BUILD**: Run the build. Verify it passes. Fix failures.
   - **TEST**: Run tests. Fix failures. Write tests for new code.
   - **REVIEW**: Dispatch a reviewer agent. Fix issues it finds.

   The user is NOT your tester. Do not hand off broken, untested, or unreviewed code.
   Do not say "you can run the tests to verify" — YOU run them.
   Do not present review findings as a TODO list — YOU fix them.

### How enforcement works

Gates are organized by phase: `start`, `during`, `end`. The session-start hook reads `roles/{role}.yaml` and for each gate set to `true`, injects a `<gate>` block into the session context. Completion gates are merged into a single `completion_checklist` gate so they cannot be skipped individually.

## Auto-Triggers

| User phrase | Action |
|-------------|--------|
| "fix issues", "fix remaining", "address findings" | Dispatch specialist agent |
| "find where", "search for", "locate" | Dispatch explore agent |
| "visualize", "diagram" | Invoke visual skill |
| "plan", "design", "architect" | Invoke brainstorm skill |

## Precedence

- Project skill (`.forge/skills/`) > pack skill (`packs/`)
- Newer knowledge entry (`added_date`) > older entry
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
