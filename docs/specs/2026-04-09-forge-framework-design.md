# Forge: Unified Skills & Agent Framework for Claude Code

**Date:** 2026-04-09
**Status:** Design approved, pending implementation plan
**Author:** Tim Collins + Claude

## Problem Statement

Running Ring + ECC + Superpowers together creates three compounding problems:

1. **Context bloat** — ~11,500 tokens consumed at session start by skill catalogs, duplicate orchestrator rules, and per-message hook reminders. Sessions compact early, losing working memory.
2. **Fragmentation** — Three plugins with overlapping skills, inconsistent formats, and no deterministic way to resolve which skill "wins" when multiple match.
3. **Onboarding friction** — Institutional knowledge (conventions, gotchas, past decisions) lives in one person's `~/.claude/projects/.../memory/`. New team members and autonomous agents start from zero.

## Solution: Forge

A two-layer framework:

- **Layer 1 — Plugin Engine** (installed once globally): Core orchestrator, auto-detection engine, domain packs, self-eval engine.
- **Layer 2 — Repo Knowledge** (checked into each codebase): Team knowledge, project-specific skills, role configurations, eval data.

One plugin install replaces Ring + ECC + Superpowers. Shared knowledge travels with the repo via `git pull`.

## Target Users

- Mixed roles: engineers, PMs, designers
- Autonomous agents: CI bots, scheduled tasks, remote triggers
- All operating from the same shared knowledge base with role-appropriate gate enforcement

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Distribution | Single unified plugin | Eliminates conflicts, single version to track |
| Knowledge location | `.forge/` checked into repo | Versioned, reviewable in PRs, travels with `git clone` |
| Pack activation | Auto-detected + opt-in | Zero-config for stack packs, explicit for domain packs |
| Gate enforcement | All Ring gates preserved | Discipline is the point; the problem was token cost, not the gates |
| Token strategy | Progressive disclosure (3 tiers) | ~79% reduction in baseline context cost |
| Self-improvement | Built in from day one | Track, score, prune, promote — team-visible in repo |
| Personal vs shared | Two layers, personal overrides shared | Team knowledge in `.forge/`, personal in `~/.claude/` |

---

## 1. Plugin Engine Structure

```
forge/
├── .claude-plugin/
│   └── plugin.json
├── core/                        # ALWAYS loaded (~300 tokens)
│   ├── orchestrator.md          # gates, dispatch, 3-file rule
│   ├── detection.sh             # stack scanner
│   └── pack-loader.md           # progressive disclosure logic
├── agents/                      # shared agents
│   ├── explorer.md
│   ├── planner.md
│   └── reviewer.md
├── packs/                       # domain packs
│   ├── nextjs/
│   │   ├── pack.yaml            # metadata + detection rules
│   │   ├── skills/
│   │   ├── agents/
│   │   └── shared-patterns/
│   ├── react/
│   ├── supabase/
│   ├── tailwind/
│   ├── typescript/
│   ├── golang/
│   ├── python/
│   ├── docker/
│   ├── healthcare/              # opt-in domain pack
│   ├── planning/                # opt-in role pack
│   ├── leadership/              # opt-in role pack
│   └── writing/                 # opt-in role pack
├── hooks/
│   └── hooks.json
├── commands/
│   └── forge-init.md
└── eval/
    ├── scorer.md
    └── telemetry.sh
```

### Pack Anatomy

Each pack is self-contained with a `pack.yaml` manifest:

```yaml
name: nextjs
detect:
  files: [next.config.*]
  deps: [next]
  dirs: [src/app/]
roles: [engineer, designer]
skills: 12
agents: 3
```

Detection rules are evaluated by `detection.sh` at session start. If any rule matches, the pack activates.

### Progressive Disclosure: Three Tiers

| Tier | When Loaded | Token Cost | Contents |
|------|------------|------------|----------|
| 1. Metadata | Session start (for activated packs) | ~20 tokens/skill | Name + one-line description |
| 2. Instructions | When skill is invoked | ~500-2,000 tokens/skill | Full SKILL.md workflow |
| 3. Resources | When skill needs deep reference | Unbounded | Shared patterns, scripts, examples |

**Token budget comparison:**

| Component | Current (Ring+ECC+Superpowers) | Forge |
|-----------|-------------------------------|-------|
| Skill catalog | ~4,000 | ~1,000 (metadata only) |
| Orchestrator rules | ~2,000 | ~300 |
| Using-superpowers | ~1,500 | 0 (merged into core) |
| Hook reminders/message | ~1,000 | 0 (loaded once) |
| CLAUDE.md | ~3,000 | ~500 |
| **Total baseline** | **~11,500** | **~2,400** |

---

## 2. Repo Knowledge Layer

```
.forge/
├── knowledge/                   # team knowledge base
│   ├── INDEX.md                 # manifest (loaded at session start)
│   ├── decisions/
│   │   ├── auth-pattern.md
│   │   ├── stakeholder-codes.md
│   │   └── api-conventions.md
│   ├── conventions/
│   │   ├── component-patterns.md
│   │   ├── db-schema-rules.md
│   │   └── error-handling.md
│   └── gotchas/
│       ├── server-client-context.md
│       └── empty-array-truthy.md
├── skills/                      # project-specific skills
│   ├── deploy-to-netlify/
│   │   └── SKILL.md
│   ├── run-assessment-flow/
│   │   └── SKILL.md
│   └── supabase-migration/
│       └── SKILL.md
├── roles/                       # role gate configurations
│   ├── engineer.yaml
│   ├── pm.yaml
│   ├── designer.yaml
│   └── agent.yaml
├── eval/                        # self-improvement data
│   ├── scores.json
│   ├── usage.jsonl
│   └── reports/
│       └── 2026-04-09.md
└── forge.yaml                   # project configuration
```

### Knowledge File Format

```yaml
---
type: gotcha                     # decision | convention | gotcha
severity: critical               # critical | warning | info
summary: >
  Server-side Supabase client used from client components
  causes misleading "Invalid API key" errors
tags: [supabase, auth, ssr, debugging]
added_by: tim
added_date: 2026-03-15
---

# Server vs Client Supabase Context

## The Problem
Using `supabaseServer` in a client component produces "Invalid API key"
but the real issue is wrong execution context.

## The Rule
- Server: `supabaseServer` from `/lib/supabase-server`
- Client: `supabase` from `/lib/supabaseClient`

## How to Detect
If you see "Invalid API key" check which import the component uses
before investigating the key itself.
```

### INDEX.md

Auto-generated manifest loaded at session start. One line per knowledge entry using the `summary` field. Full file content loads only when the orchestrator detects relevance to the current task.

```markdown
# Team Knowledge Index

## Decisions
- [auth-pattern](decisions/auth-pattern.md) — Supabase RLS for all auth; service role server-only
- [stakeholder-codes](decisions/stakeholder-codes.md) — Financial stakeholder code is REVENUE not FINANCIAL
- [api-conventions](decisions/api-conventions.md) — REST endpoints use /api/{resource}, Zod validation on all inputs

## Conventions
- [component-patterns](conventions/component-patterns.md) — PortalPageHeader uses subtitle not description
- [db-schema-rules](conventions/db-schema-rules.md) — JOINs over duplication; FK to lookup tables
- [error-handling](conventions/error-handling.md) — All delete ops require confirmation modal + toast

## Gotchas
- [server-client-context](gotchas/server-client-context.md) — [critical] Server supabase client in client component = misleading errors
- [empty-array-truthy](gotchas/empty-array-truthy.md) — [] is truthy; use arr?.length not arr || fallback
```

### Knowledge Loading Strategy

At session start, the orchestrator:
1. Loads INDEX.md (~500 tokens budget, configurable via `knowledge_budget` in forge.yaml)
2. Prioritizes by severity (critical first) then recency if budget is tight
3. Loads full knowledge file content on demand when the task context matches tags/summary

Personal memory in `~/.claude/projects/.../memory/` continues to work as-is. The orchestrator merges both layers: team knowledge first, personal overrides second.

### forge.yaml

```yaml
# Auto-detected packs are implicit. Only list overrides.
extra_packs:
  - healthcare
  - leadership
  - planning

suppress_packs:
  - docker              # Dockerfile exists but unused

knowledge_budget: 500   # max tokens for INDEX at session start
default_role: engineer
```

---

## 3. Orchestrator & Gates

### Core Orchestrator (~300 tokens, always loaded)

**Hard Gates (never bypassed):**
1. **3-File Rule** — >3 files touched = dispatch agent. No exceptions.
2. **Skill Check** — Before any action, check if a skill applies. Use it.
3. **Role Gates** — Load role config, enforce only the gates assigned to this role.
4. **Knowledge First** — Check `.forge/knowledge/` before making assumptions.

**Auto-Triggers:**
- `"fix issues/remaining"` → specialist agent
- `"find where/search for"` → explore agent
- `"visualize/diagram"` → visual skill
- `"plan/design/architect"` → brainstorm skill

### What Changed vs Ring

**Removed (token savings):**
- Full skill catalog listing (~4K tokens) → replaced by pack metadata (~20 tokens/skill)
- Duplicate orchestrator rules (3 plugins saying the same thing) → one orchestrator
- Per-message hook reminder injection (~1K tokens/message) → knowledge loaded once at start

**Kept (discipline preserved):**
- 3-file rule
- Development cycle gates (plan → implement → test → review → validate)
- Mandatory skill invocation
- Auto-trigger phrase dispatch
- Doubt-triggered questions

**New:**
- **Knowledge Gate** — Check `.forge/knowledge/` before making assumptions about conventions
- **Role-Scoped Enforcement** — Same gates, different application per role
- **Precedence Resolution** — Project skill > pack skill. Newer knowledge > older. Deterministic.

### Role Gate Configurations

Defined in `.forge/roles/`. Each role gets a subset of gates:

| Gate | Engineer | PM | Designer | Agent (CI) |
|------|----------|-----|----------|------------|
| 3-file rule | Yes | No | No | Yes |
| Skill check | Yes | Yes | Yes | No |
| Knowledge gate | Yes | Yes | Yes | Yes |
| Dev cycle (all) | Yes | No | No | No |
| Pre-dev planning | Yes | Yes | No | No |
| Code review (7 reviewers) | Yes | No | No | No |
| Build verification | Yes | No | No | Yes |
| Test gate | Yes | No | No | Yes |
| Auto-triggers | Yes | No | No | Yes |
| Doubt-triggered questions | Yes | Yes | No | No |
| Brainstorming | Yes | Yes | Yes | No |
| Visual companion | Yes | No | Yes | No |
| Design system | No | No | Yes | No |
| Accessibility gates | No | No | Yes | No |

---

## 4. Auto-Detection Engine

### Detection Flow (session start, ~2 seconds)

1. **Run detection.sh** — Shell hook at SessionStart scans repo root for marker files
2. **Match pack rules** — Each pack's `pack.yaml` has detect rules (files, deps, dirs)
3. **Check forge.yaml** — Repo config adds extra packs or suppresses auto-detected ones
4. **Load metadata** — Only Tier 1 (name + description) for each activated pack's skills
5. **Emit manifest** — Active packs + skill metadata injected into session context

### Detection Rules

| Pack | Detect: Files | Detect: Deps | Detect: Dirs |
|------|--------------|-------------|-------------|
| nextjs | `next.config.*` | `next` | `src/app/` |
| react | — | `react` | `src/components/` |
| supabase | `supabase/config.toml` | `@supabase/supabase-js` | `supabase/migrations/` |
| tailwind | `tailwind.config.*` | `tailwindcss` | — |
| typescript | `tsconfig.json` | `typescript` | — |
| golang | `go.mod` | — | — |
| python | `pyproject.toml`, `requirements.txt` | — | — |
| docker | `Dockerfile`, `docker-compose.*` | — | — |

Domain/role packs (healthcare, planning, leadership, writing) have no file markers — activated via `extra_packs` in `forge.yaml`.

### Override Mechanism

```yaml
# forge.yaml
extra_packs: [healthcare, leadership]    # add packs with no markers
suppress_packs: [docker]                  # silence irrelevant detections
```

### Example: reefo-frontend

Auto-detected: nextjs, react, supabase, tailwind, typescript, docker (6 packs)
Opt-in: healthcare, leadership, planning (3 packs)
**Total: 9 packs, ~71 skills, ~16 agents, ~1,420 tokens metadata, 98.3% deferred**

---

## 5. Self-Improvement Loop

### Feedback Cycle

Invoke → Record → Score → Act → Report

Every skill invocation is logged to `.forge/eval/usage.jsonl` by a SessionEnd hook.

### What Gets Recorded

```jsonl
{"skill":"nextjs:app-router","outcome":"completed","date":"2026-04-09","role":"engineer","session":"abc123","duration_turns":4,"user_override":false}
{"skill":"react:tdd-workflow","outcome":"overridden","date":"2026-04-09","role":"engineer","session":"abc123","duration_turns":1,"user_override":true,"override_reason":"too slow for hotfix"}
{"skill":"golang:build-resolver","outcome":"skipped","date":"2026-04-09","role":"engineer","session":"abc123","reason":"no_go_files_in_change"}
{"knowledge":"gotchas/server-client-context","outcome":"consulted","date":"2026-04-09","role":"engineer","session":"abc123","prevented_mistake":true}
```

### Scoring: Four Tiers (0-100)

| Tier | Score | Criteria | Action |
|------|-------|----------|--------|
| Bronze | 40-59 | <5 invocations, >30% override rate | Flag for review |
| Silver | 60-79 | 5-20 invocations, moderate completion | Keep, monitor |
| Gold | 80-89 | 20+ invocations, >80% completion, rarely overridden | Promote to team default |
| Platinum | 90+ | 50+ invocations, near-zero override, prevents known mistakes | Candidate for core pack |

### Scoring Dimensions

| Dimension | Weight | What It Measures |
|-----------|--------|------------------|
| Adoption | 0-25 | How often invoked, discovered naturally vs explicitly called |
| Completion | 0-25 | Follow-through rate when invoked |
| Impact | 0-25 | Prevented known mistakes, cross-referenced with knowledge entries |
| Efficiency | 0-15 | Turns added to session (fewer = better) |
| Cross-Role | 0-10 | Useful across multiple roles |

### Eval Agent

- **On demand:** `/forge eval` runs full analysis
- **Scheduled:** Weekly via remote trigger (if configured)
- **Auto-triggered:** After 50 new usage entries
- **Produces:** Updated `scores.json`, human-readable report in `reports/YYYY-MM-DD.md`, recommendations (prune, promote, revise)
- **Usage log hygiene:** Entries older than 30 days auto-pruned to aggregate scores

All eval data lives in `.forge/eval/` and gets committed to the repo (except raw `usage.jsonl` which is gitignored). The team reviews skill performance in PRs.

---

## 6. Bootstrap & Migration

### `/forge init` — For Existing Repos

Interactive 4-step bootstrap:

1. **Detect & Confirm Stack** — Scans repo, proposes packs. User confirms or adjusts.
2. **Extract Knowledge from CLAUDE.md** — AI classifies existing CLAUDE.md content into decisions, conventions, gotchas. Proposes knowledge files.
3. **Import Personal Memories** — Scans `~/.claude/projects/.../memory/` for team-relevant entries. Proposes which to promote to shared knowledge. Skips personal preferences.
4. **Scaffold & Generate** — Creates `.forge/`, writes `forge.yaml`, generates INDEX.md, creates default role configs, produces lean CLAUDE.md (~500 tokens).

### Migration from Ring + ECC + Superpowers

1. Install Forge plugin from marketplace
2. Run `/forge init` in each repo (~5 min per repo)
3. Review generated knowledge files in a PR
4. Commit `.forge/` and lean `CLAUDE.md`
5. Disable old plugins in `~/.claude/settings.json`
6. Parallel run for 1 week (optional) — old plugins disabled but installed for rollback
7. Uninstall old plugins after validation

### .gitignore Guidance

**Commit these** (shared team knowledge):
- `.forge/knowledge/`
- `.forge/skills/`
- `.forge/roles/`
- `.forge/forge.yaml`
- `.forge/eval/scores.json`
- `.forge/eval/reports/`

**Add to .gitignore** (machine-specific):
```gitignore
.forge/eval/usage.jsonl
```

---

## 7. Edge Cases

| Scenario | Behavior |
|----------|----------|
| No `.forge/` in repo | Core orchestrator + auto-detected packs work normally. Suggests `/forge init`. |
| Conflicting knowledge entries | Newer `added_date` wins. Same date → orchestrator flags conflict, asks user. |
| Knowledge budget exceeded | Prioritize by severity (critical first) then recency. Truncated entries available on demand. |
| Pack skill conflicts with project skill | Project skill always wins. |
| Multi-repo teams | Each repo has own `.forge/`. Use `/forge init --template org-defaults` for shared baseline. |
| detection.sh fails/times out | Falls back to `forge.yaml` explicit pack list. No forge.yaml → core only. |
| eval/usage.jsonl too large | Eval agent rolls up old entries to aggregate scores. Raw logs >30 days pruned. |
| User has no role set | Uses `default_role` from forge.yaml. Set with `/forge role <name>`, persists to `~/.claude/forge-role`. |

---

## Success Criteria

1. **Baseline context cost < 2,500 tokens** (vs ~11,500 today)
2. **New team member productive in < 10 minutes** (install plugin + clone repo)
3. **Zero skill conflicts** between packs (deterministic precedence)
4. **All Ring gates preserved** with role-scoped enforcement
5. **Self-eval produces actionable reports** within 2 weeks of usage
6. **Knowledge entries reviewable in PRs** like any other code change
