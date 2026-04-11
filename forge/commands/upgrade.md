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

### Step 1: Locate Plugin and Check for Updates

Run this EXACT command as a single Bash tool call. Do NOT break it up, improvise discovery, or run extra commands.

```bash
PLUGIN_DIR=""; for dir in "${CLAUDE_PLUGIN_ROOT:-}" "$HOME/.claude/plugins/forge" "/Users/timcollins/forge-framework/forge"; do [ -n "$dir" ] && [ -d "$dir/.claude-plugin" ] && PLUGIN_DIR="$dir" && break; done; if [ -z "$PLUGIN_DIR" ]; then echo "NOT_FOUND"; exit 0; fi; GIT_ROOT=$(git -C "$PLUGIN_DIR" rev-parse --show-toplevel 2>/dev/null); if [ -z "$GIT_ROOT" ]; then echo "NOT_GIT"; exit 0; fi; cd "$GIT_ROOT" && LOCAL=$(git rev-parse HEAD) && git fetch origin main 2>&1 && REMOTE=$(git rev-parse origin/main) && VERSION=$(grep '"version"' "$PLUGIN_DIR/.claude-plugin/plugin.json" | sed 's/.*"version": *"//;s/".*//') && if [ "$LOCAL" = "$REMOTE" ]; then echo "UP_TO_DATE|$LOCAL|v$VERSION"; else echo "UPDATE_AVAILABLE|$LOCAL|$REMOTE|v$VERSION"; fi
```

Parse the output:
- `NOT_FOUND` → Plugin not installed. Suggest reinstalling.
- `NOT_GIT` → Plugin directory exists but is not inside a git repo. Suggest reinstalling.
- `UP_TO_DATE|<hash>|v<version>` → Report "Forge is up to date" with version and short hash FROM THE OUTPUT
- `UPDATE_AVAILABLE|<local>|<remote>|v<version>` → Report "Update available" and continue to Step 2

IMPORTANT: The version number MUST come from the command output, not from memory or prior context.

If `--check` flag was passed, stop here. Otherwise continue to Step 2.

### Step 2: Pull Latest

Using the same `GIT_ROOT` from Step 1, run:

```bash
cd <GIT_ROOT> && LOCAL=$(git rev-parse HEAD) && git pull origin main --ff-only && REMOTE=$(git rev-parse HEAD) && git log --oneline $LOCAL..$REMOTE
```

If fast-forward fails (local changes exist):
- Report the conflict
- Suggest: `cd <GIT_ROOT> && git stash && git pull origin main --ff-only && git stash pop`
- Do NOT force-pull or discard changes

Format the result as:

```
## Forge upgraded

**Previous:** v0.1.0 (abc1234)
**Current:**  v0.1.1 (def5678)

### Changes
- fix: enforce gates via session-start hook injection
- feat: add new pack for X

Run `/clear` or start a new session to pick up the changes.
```

## Checklist

- [ ] Plugin directory found via single discovery command
- [ ] Git fetch succeeded (network available)
- [ ] Pull was fast-forward (no local modifications lost)
- [ ] Changelog displayed
- [ ] User reminded to restart session
