---
name: forge:orchestrator
description: |
  Core orchestrator for Forge. Enforces mandatory gates,
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
