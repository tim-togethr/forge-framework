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
