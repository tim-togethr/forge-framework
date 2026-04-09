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
