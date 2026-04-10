# CLAUDE.md

Forge is active. Team knowledge and coding standards are managed in `.forge/`.

- Run `/forge status` to see active packs and skills.
- Run `/forge role <role>` to switch your active role.

## Quick Reference

- **No compiled code** — this repo is markdown, YAML, JSON, and shell scripts only.
- **Test packs**: `for pack in forge/packs/*/; do bash tests/validate-pack.sh "$pack"; done`
- **Test detection**: `bash tests/test-detection.sh`
- **Add a pack**: See `.forge/knowledge/team.md` for the full process.
