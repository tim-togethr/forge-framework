---
description: "Run skill quality evaluation — scores skills, produces report, recommends actions"
---

# /forge eval

Evaluate skill quality and usage across your Forge installation. Reads telemetry from `.forge/eval/usage.jsonl`, scores skills across 5 dimensions, assigns tiers, generates a human-readable report, and writes updated scores to `.forge/eval/scores.json`.

## Usage

```bash
/forge eval
```

No arguments required. Reads from the usage log automatically.

## How It Works

### 1. Read Usage Data

Reads `.forge/eval/usage.jsonl` — each line is a JSON record:

```json
{"skill":"react:hooks","outcome":"completed","date":"2026-04-09","role":"engineer","session":"abc123","user_override":false}
{"skill":"react:hooks","outcome":"skipped","date":"2026-04-09","role":"pm","session":"def456","user_override":true,"override_reason":"not relevant to planning task"}
```

Filters to the last 90 days by default.

### 2. Score Across 5 Dimensions

| Dimension | Weight | Description |
|-----------|--------|-------------|
| Adoption | 25 pts | How often is the skill triggered vs. available opportunities? |
| Completion | 25 pts | When triggered, how often does the session complete with no override? |
| Impact | 25 pts | Outcomes marked "completed" vs. "skipped" or "overridden" |
| Efficiency | 15 pts | Average skill load-to-use time; low friction = high score |
| Cross-Role | 10 pts | Used by multiple roles (breadth of relevance) |
| **Total** | **100 pts** | |

### 3. Assign Tiers

| Tier | Score Range | Meaning |
|------|-------------|---------|
| Platinum | 85-100 | Consistently used, high impact, multi-role adoption |
| Gold | 70-84 | Reliable, well-adopted, minor friction |
| Silver | 50-69 | Moderate adoption, room to improve triggers or content |
| Bronze | 0-49 | Low adoption or high override rate — review or prune |

### 4. Generate Report

Writes `.forge/eval/reports/YYYY-MM-DD.md`:

```markdown
# Forge Eval Report — 2026-04-09

## Summary
- Skills evaluated: 18
- Platinum: 3 | Gold: 7 | Silver: 5 | Bronze: 3

## Top Performers
| Skill | Score | Tier |
|-------|-------|------|
| typescript:strict-mode | 91 | Platinum |
| react:component-patterns | 88 | Platinum |

## Needs Attention (Bronze)
| Skill | Score | Issue | Recommendation |
|-------|-------|-------|----------------|
| docker:dockerfile-patterns | 38 | Low adoption (3 triggers in 90 days) | Review trigger conditions or team context |
| leadership:sprint-planning | 42 | High override rate (67%) | Override reasons suggest skill is too prescriptive |

## Override Analysis
Most common override reasons:
1. "not relevant to task" (12 times) → triggers firing too broadly
2. "already done" (8 times) → skip_when conditions need updating
3. "different tech stack" (3 times) → detection rules may need adjustment

## Recommended Actions
- [ ] Update `docker:dockerfile-patterns` trigger — too generic
- [ ] Add skip_when to `leadership:sprint-planning` for non-planning contexts
- [ ] Promote `typescript:strict-mode` to core (always-on)
```

### 5. Update scores.json

Writes `.forge/eval/scores.json`:

```json
{
  "generated_at": "2026-04-09T12:00:00Z",
  "window_days": 90,
  "skills": {
    "typescript:strict-mode": {
      "score": 91,
      "tier": "Platinum",
      "adoption": 24,
      "completion": 23,
      "impact": 22,
      "efficiency": 13,
      "cross_role": 9,
      "last_used": "2026-04-09"
    }
  }
}
```

### 6. Prune Old Data

Automatically moves records older than 90 days from `usage.jsonl` to `usage.jsonl.archive-YYYY` to keep the active log lean.

## Checklist

- [ ] `.forge/eval/usage.jsonl` exists with at least 7 days of data for meaningful scores
- [ ] Report reviewed — action items assigned to a team member
- [ ] Bronze skills triaged (improve trigger, update content, or retire)
- [ ] Platinum skills considered for promotion to always-on core rules
