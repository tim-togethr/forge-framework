---
description: "Pull the latest Forge plugin version and report what changed"
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

Run this EXACT command (do not omit the VERSION line):

```bash
cd <plugin-directory> && LOCAL=$(git rev-parse HEAD) && git fetch origin main 2>&1 && REMOTE=$(git rev-parse origin/main) && VERSION=$(grep '"version"' .claude-plugin/plugin.json | sed 's/.*"version": *"//;s/".*//') && if [ "$LOCAL" = "$REMOTE" ]; then echo "UP_TO_DATE|$LOCAL|v$VERSION"; else echo "UPDATE_AVAILABLE|$LOCAL|$REMOTE|v$VERSION"; fi
```

Parse the output:
- `UP_TO_DATE|<hash>|v<version>` → Report "Forge is up to date" using the version FROM THE OUTPUT (do NOT guess or hardcode a version)
- `UPDATE_AVAILABLE|<local>|<remote>|v<version>` → Report "Update available"

IMPORTANT: The version number MUST come from the command output, not from memory or prior context.

If `--check` flag was passed, stop here. Otherwise continue to Step 3.

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
