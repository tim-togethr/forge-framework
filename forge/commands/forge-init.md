---
name: forge:init
description: Bootstrap .forge/ directory in an existing repo with team knowledge, role configs, and auto-detected packs
argument-hint: "[--template <name>]"
---

# /forge init

Bootstrap the `.forge/` directory in an existing repository. Detects your stack, extracts knowledge from existing CLAUDE.md, imports personal memories, and generates a lean CLAUDE.md that delegates to Forge.

## Usage

```bash
/forge init
/forge init --template nextjs-saas
/forge init --template api-service
```

## Arguments

| Argument | Description |
|----------|-------------|
| `--template <name>` | Pre-configured template to scaffold from. Options: `nextjs-saas`, `api-service`, `data-pipeline`, `mobile`. Defaults to auto-detect. |

## What It Does

### Step 1: Detect Stack

Scans the repository for detection signals across all available packs:

- Reads `package.json`, `go.mod`, `pyproject.toml`, `requirements.txt`
- Checks for `tsconfig.json`, `tailwind.config.*`, `Dockerfile`, `docker-compose.*`
- Scans for `supabase/config.toml`, `supabase/migrations/`
- Checks `src/components/` for React, `src/app/` for Next.js

Reports detected packs and asks for confirmation.

### Step 2: Extract Knowledge from CLAUDE.md

If a `CLAUDE.md` exists in the repo root:

- Reads all sections
- Identifies team-specific rules, patterns, and conventions
- Extracts architecture decisions, naming conventions, and anti-patterns
- Asks: "I found these rules in your CLAUDE.md — should I preserve them in `.forge/knowledge/`?"

Preserves team knowledge in `.forge/knowledge/team.md` without losing existing documentation.

### Step 3: Import Personal Memories

Checks `~/.claude/CLAUDE.md` for personal preferences:

- Role configuration
- Tool preferences
- Personal shortcuts

Asks: "I found personal preferences — should I copy them to `.forge/config.yaml`?"

### Step 4: Scaffold `.forge/` and Generate CLAUDE.md

Creates the directory structure:

```
.forge/
├── config.yaml          # repo-level config (role, packs, gates)
├── knowledge/
│   └── team.md          # extracted team knowledge
└── eval/
    └── usage.jsonl      # telemetry log (starts empty)
```

Generates a lean `CLAUDE.md` that delegates to Forge instead of duplicating rules:

```markdown
# CLAUDE.md

Forge is active. Team knowledge and coding standards are managed in `.forge/`.

Run `/forge status` to see active packs and skills.
Run `/forge role <role>` to switch your active role.
```

## Generated .forge/config.yaml

```yaml
role: engineer
packs:
  auto: true        # auto-detect from project files
  opt_in: []        # additional packs to always load
gates:
  build_verification: true
  test_gate: true
  three_file_rule: true
```

## Checklist

- [ ] Run from repo root (not a subdirectory)
- [ ] Commit `.forge/` to version control
- [ ] Add `.forge/eval/usage.jsonl` to `.gitignore` (contains session data)
- [ ] Review generated `CLAUDE.md` before committing
