---
name: forge:upgrade
description: Pull the latest Forge plugin version and report what changed
argument-hint: "[--check]"
---

# /forge upgrade

Pull the latest version of the Forge plugin from the upstream repository.

## Usage

```bash
/forge upgrade          # Pull latest and show changelog
/forge upgrade --check  # Check for updates without pulling
```

## What It Does

### Step 1: Locate the Plugin

Find the Forge plugin installation directory. Check these locations in order:

1. `$CLAUDE_PLUGIN_ROOT` environment variable (set by Claude Code when running as a plugin)
2. `~/.claude/plugins/forge/` (standard plugin install path)
3. `/Users/timcollins/forge-framework/forge/` (development install)

If none found, report error and suggest reinstalling.

### Step 2: Check for Updates

```bash
cd <plugin-directory>
git fetch origin main 2>/dev/null
```

Compare local HEAD with origin/main:

```bash
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)
```

If `--check` flag was passed:
- If `LOCAL == REMOTE`: Report "Forge is up to date (v{version})"
- If `LOCAL != REMOTE`: Report "Update available" and show commit summary

If `--check` was NOT passed, continue to Step 3.

### Step 3: Pull Latest

```bash
git pull origin main --ff-only
```

If fast-forward fails (local changes exist):
- Report the conflict
- Suggest: `cd <plugin-dir> && git stash && git pull origin main --ff-only && git stash pop`
- Do NOT force-pull or discard changes

### Step 4: Show Changelog

After pulling, show what changed:

```bash
git log $LOCAL..$REMOTE --oneline
```

Format as:

```
## Forge upgraded

**Previous:** v0.1.0 (abc1234)
**Current:**  v0.1.1 (def5678)

### Changes
- fix: enforce gates via session-start hook injection
- feat: add new pack for X

Restart your Claude Code session to pick up the changes.
```

### Step 5: Suggest Session Restart

Gate enforcement and hook changes only take effect on session start. Remind the user:

> "Changes are pulled. Run `/clear` or start a new session to activate them."

## Checklist

- [ ] Plugin directory found
- [ ] Git fetch succeeded (network available)
- [ ] Pull was fast-forward (no local modifications lost)
- [ ] Changelog displayed
- [ ] User reminded to restart session
