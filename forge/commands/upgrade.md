---
description: "Pull the latest Forge plugin version and report what changed"
---

# /forge upgrade

Pull the latest version of the Forge plugin from the upstream repository.

## Execution

The upgrade script is at `scripts/upgrade.sh` relative to the Forge plugin root
(one directory up from this command file: `../scripts/upgrade.sh`).

Run the script and display its output exactly as printed. Do not reformat,
add commentary, or run additional commands.

```bash
# Upgrade (fetch + pull + changelog):
bash "<FORGE_PLUGIN_DIR>/scripts/upgrade.sh"

# Check only (no pull):
bash "<FORGE_PLUGIN_DIR>/scripts/upgrade.sh" --check
```

To resolve `<FORGE_PLUGIN_DIR>`, use the path this command file was loaded from
minus `/commands/upgrade.md`. For example, if you read this file from
`/Users/x/forge-framework/forge/commands/upgrade.md`, the script is at
`/Users/x/forge-framework/forge/scripts/upgrade.sh`.

IMPORTANT: The script handles ALL logic — discovery, version reading, git
operations, and output formatting. Run ONLY the script. Do NOT run your own
git commands, do NOT improvise discovery, do NOT parse package.json or any
other file. One bash call, one script, done.
