# Forge

Unified skills & agent framework for Claude Code.

Replaces Ring + ECC + Superpowers with a two-layer architecture:

- **Plugin Engine** (installed once globally) — Core orchestrator, auto-detection engine, domain packs, self-eval engine
- **Repo Knowledge** (checked into each codebase) — Team knowledge, project-specific skills, role configurations, eval data

## Key Features

- **Progressive disclosure** — ~79% reduction in baseline context cost (from ~11,500 to ~2,400 tokens)
- **Auto-detection** — Scans your repo for stack markers, activates only relevant packs
- **Shared team knowledge** — Decisions, conventions, and gotchas checked into the repo as `.forge/`
- **Role-scoped gates** — Engineers get full dev cycle gates, PMs get planning gates, agents get critical-path only
- **Self-improvement** — Every skill invocation is tracked, scored, and reported. Bad skills get pruned, good ones promoted.
- **Mandatory gates preserved** — 3-file rule, dev cycle gates, mandatory skill invocation, auto-trigger dispatch

## Status

Design phase. See [docs/specs/2026-04-09-forge-framework-design.md](docs/specs/2026-04-09-forge-framework-design.md) for the full specification.

## License

MIT
