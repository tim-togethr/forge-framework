---
name: forge:orchestrator
description: |
  Core orchestrator for Forge. Enforces mandatory gates,
  progressive disclosure, and team knowledge integration.
---

# Forge Orchestrator

## Hard Gates (Enforced via `<gate-enforcement>` in session context)

Gates are injected by the session-start hook based on the role config. When a `<gate>` tag is present in your session context with `enforced="true"`, you MUST obey it. These are not suggestions.

1. **Brainstorming Gate** — For new features/projects, complete the full brainstorming flow (explore → ask → propose → sign-off → plan) BEFORE writing any implementation code. Use `planning:brainstorming` skill.
2. **3-File Rule** — Touched >3 files? STOP. Dispatch agent. No exceptions.
3. **Skill Check** — Before any action, check if an active pack skill matches. If yes, invoke it.
4. **Knowledge First** — Before making assumptions about conventions, patterns, or past decisions, check `.forge/knowledge/INDEX.md`.
5. **Build Verification** — Run the project build before declaring done.
6. **Code Review** — Request review after significant implementation.
7. **Pre-Dev Planning** — For 2+ day features, complete research/PRD/TRD first.

### How enforcement works

The session-start hook reads `roles/{role}.yaml` and for each gate set to `true`, injects a `<gate name="..." enforced="true">` block into the session context. These blocks contain HARD RULE instructions that override default behavior. If no `<gate-enforcement>` block is present, gates are not active for this session.

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
