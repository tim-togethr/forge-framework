---
name: writing:technical-docs
description: Technical writing — title, summary, quick start, concepts, reference, troubleshooting, active voice, show don't tell
trigger: |
  - Writing documentation for a feature, API, or system
  - Updating existing docs that are incomplete or outdated
  - Creating a README, guide, or reference page
  - Onboarding documentation for new team members
skip_when: |
  - Inline code comments (use code comment conventions instead)
  - Short Slack/PR descriptions
---

# Technical Documentation

## Document Structure

Every technical document follows this structure (adapt sections as needed):

```
1. Title — describes the subject, not the action
2. Summary — 2-3 sentences: what it is, who it's for, what problem it solves
3. Quick Start — working example in < 5 minutes
4. Concepts — key terms and mental models
5. Reference — complete API/config/options
6. Troubleshooting — common errors with solutions
```

## Title

State the subject. Don't use gerunds ("Configuring X") — use noun phrases ("Configuration Reference") or imperatives ("Configure X").

```
BAD:  "Using the Authentication System"
GOOD: "Authentication — Setup and Reference"

BAD:  "How to Deploy"
GOOD: "Deployment Guide"
```

## Summary

3 sentences max. Answer: what is this, who uses it, what does it solve.

```markdown
The Forge plugin injects team knowledge into Claude Code sessions automatically.
It is used by development teams who want consistent code patterns and conventions
enforced without manual prompting. Forge eliminates "context-setting overhead"
by detecting your stack and loading relevant rules at session start.
```

## Quick Start

The fastest path to working. Real commands, real code, real output.

```markdown
## Quick Start

Install and try in 3 minutes:

```bash
# 1. Add plugin to Claude Code
claude mcp add forge

# 2. Initialize in your repo
/forge init

# 3. Verify detection
/forge status
```

Expected output:
```
Forge v0.1.0 active
Detected packs: typescript, nextjs, react
Role: engineer
3 skills loaded
```
```

## Concepts

Define terms before using them. One concept per subsection.

```markdown
## Concepts

### Pack
A pack is a collection of skills grouped by technology (e.g., `react`, `supabase`).
Packs are either auto-detected from your project files or opted into manually.

### Skill
A skill is a markdown file containing rules and examples for a specific coding pattern.
Skills are loaded based on what you're doing, not pre-loaded in bulk.
```

## Reference

Complete, scannable. Use tables for options, code blocks for every example.

```markdown
## Configuration Reference

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `role` | string | `engineer` | Active role — gates which skills apply |
| `packs` | string[] | auto | Additional packs to load beyond detected ones |

### pack.yaml Fields

```yaml
name: string          # Required. Unique pack identifier
description: string   # Required. One-line description
detect:               # Optional. Auto-detect rules
  files: string[]     # Presence of these files triggers detection
  deps: string[]      # package.json dependency names
  dirs: string[]      # Directory paths that must exist
roles: string[]       # Required. Roles that load this pack
```
```

## Troubleshooting

Exact error message → exact fix. Do not describe symptoms — show the error.

```markdown
## Troubleshooting

### "No packs detected"

**Cause**: No detection rules matched your project files.

**Fix**: Run `/forge init` to configure packs manually, or verify your project
has the expected files (e.g., `tsconfig.json` for the TypeScript pack).

### "Skill 'react:hooks' not found"

**Cause**: The `react` pack is not loaded in this session.

**Fix**: Add `react` to your opt-in packs:
```yaml
# .forge/config.yaml
packs: [react]
```
```

## Writing Style

**Active voice, present tense**:
- "The pack loads skills" not "Skills are loaded by the pack"
- "Run the command" not "The command should be run"

**Show, don't tell**:
- "Forge reduces context-setting time" → show benchmark or example
- "This is a powerful feature" → delete the word "powerful" and show the capability

**One idea per sentence.** If a sentence has two clauses joined by "and", consider splitting it.

## Checklist

- [ ] Title is a noun phrase or imperative, not a gerund
- [ ] Summary covers what, who, and problem solved in ≤ 3 sentences
- [ ] Quick Start has working commands/code (tested)
- [ ] All terms defined in Concepts before use in Reference
- [ ] Reference has a complete options table
- [ ] Troubleshooting shows exact error messages and exact fixes
- [ ] Active voice throughout
- [ ] No filler adjectives ("powerful", "simple", "easy")
