---
description: "Pull the latest Forge plugin version and report what changed"
---

# /forge upgrade

Your session context contains `<plugin-dir>` with the exact Forge plugin path.
Run this command using that path. Do NOT modify, split, or improvise.

**Upgrade:**

```bash
bash "<plugin-dir>/scripts/upgrade.sh"
```

**Check only (no pull):**

```bash
bash "<plugin-dir>/scripts/upgrade.sh" --check
```

Replace `<plugin-dir>` with the literal value from your `<forge-session>` context
(e.g. if it says `<plugin-dir>/Users/x/forge/</plugin-dir>`, run
`bash "/Users/x/forge/scripts/upgrade.sh"`).

Display the script output exactly as printed. Do NOT run any other commands.
