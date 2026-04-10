---
description: "Set your role for gate enforcement (engineer, pm, designer, agent)"
---

# /forge role

Set the active role for the current session. Role controls which gates are enforced and which packs are available.

## Usage

```bash
/forge role engineer
/forge role pm
/forge role designer
/forge role agent
```

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `<role>` | Yes | Role to activate. One of: `engineer`, `pm`, `designer`, `agent` |

## Role Gate Matrix

| Gate | engineer | pm | designer | agent |
|------|----------|-----|---------|-------|
| three_file_rule | Yes | No | No | Yes |
| skill_check | Yes | Yes | Yes | No |
| knowledge_gate | Yes | Yes | Yes | Yes |
| dev_cycle | Yes | No | No | No |
| pre_dev_planning | Yes | Yes | No | No |
| code_review | Yes | No | No | No |
| build_verification | Yes | No | No | Yes |
| test_gate | Yes | No | No | Yes |
| auto_triggers | Yes | No | No | Yes |
| doubt_triggered_questions | Yes | No | No | No |
| brainstorming | Yes | Yes | No | No |
| visual_companion | Yes | No | Yes | No |
| design_system | No | No | Yes | No |
| accessibility_gates | No | No | Yes | No |

## Persistence

Role is written to `~/.claude/forge-role` (personal, not committed to the repo).

```bash
# View current role
cat ~/.claude/forge-role

# Contents: just the role name
engineer
```

The `.forge/config.yaml` in the repo sets the **default** role. Your personal `~/.claude/forge-role` overrides it for your sessions only.

## Role Descriptions

**engineer** — Full development gates. All disciplines enforced. Intended for development work: coding, testing, reviewing, debugging.

**pm** — Planning and knowledge gates only. No build/test/code-review gates. Intended for feature planning, spec writing, sprint management.

**designer** — Design and accessibility gates. No dev-cycle gates. Intended for UI/UX work, component design, design system management.

**agent** — Critical path only. Minimal gates for automated or scripted sessions. Build verification and test gates enforced; no interactive planning or review gates.

## Examples

```bash
# Before a planning session
/forge role pm

# Before writing code
/forge role engineer

# Before reviewing designs
/forge role designer

# For an automated CI-like agent session
/forge role agent
```
