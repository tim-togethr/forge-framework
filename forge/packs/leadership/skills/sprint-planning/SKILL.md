---
name: leadership:sprint-planning
description: Sprint planning — review backlog, capacity check, scope to 70%, S/M/L/XL sizing, dependencies
trigger: |
  - Starting a new sprint
  - Running sprint planning ceremony
  - Reviewing what to commit for the next iteration
  - Team capacity questions
skip_when: |
  - Kanban flow (no sprints)
  - Unblocking a single urgent task outside planning context
---

# Sprint Planning

## Pre-Planning Checklist (Before the Meeting)

- [ ] Product backlog prioritized and groomed (top 2x sprint capacity estimated)
- [ ] Previous sprint retrospective actions captured
- [ ] Dependencies on other teams identified
- [ ] Team availability confirmed (PTO, on-call, interviews)

## Step 1: Capacity Check

```
Sprint capacity = (working days × hours/day × team size) × focus factor

Example:
- 10 working days × 6 productive hours × 5 engineers = 300 hours raw
- Focus factor 0.7 (meetings, reviews, incidents) = 210 hours available

Convert to story points if using SP:
- If average velocity = 42 SP over last 3 sprints, use 42 SP as capacity
```

**Rule**: Never plan to 100% capacity. Target 70% to leave buffer for unexpected work.

## Step 2: Size Tickets

Use S/M/L/XL, not Fibonacci. Everyone knows what a day feels like.

| Size | Dev Time | What It Means |
|------|----------|---------------|
| S | < 4 hours | Single function, config change, small bug fix |
| M | 1-2 days | New endpoint + tests, component + integration |
| L | 3-4 days | Feature slice with multiple layers (API + DB + UI) |
| XL | > 4 days | **Must be split before accepting into sprint** |

**If a ticket is XL, it goes back to refinement.** XL in sprint = scope creep.

## Step 3: Identify Dependencies

For each candidate ticket:
1. Does it block another team?
2. Does another team need to ship something first?
3. Is there a shared infrastructure change required?

Map dependencies before committing:

```
Ticket A (S) → no deps ✓
Ticket B (M) → needs Ticket C first (C not in sprint = risk)
Ticket C (L) → depends on external API (vendor ETA unknown = BLOCK)
```

Flag blockers in planning. Don't accept blocked tickets into the sprint without a mitigation.

## Step 4: Draft Sprint Goal

One sentence that describes the value delivered, not a list of tickets.

```
BAD: "Complete tickets FE-123, BE-456, and BE-457"

GOOD: "Doctors can view and filter the patient list with real-time updates"
```

The sprint goal answers: "What is the team focused on and why does it matter?"

## Step 5: Commit

Accept tickets until you hit 70% capacity. Leave the rest in the backlog.

```
Sprint board at start:
- Committed: 35 SP (target: 42 SP × 0.7 = 29 SP)  ← slightly over, review
- In progress: 0
- Done: 0

Buffer: 7 SP for unplanned work (incidents, hotfixes)
```

## During Sprint: Scope Health

Check daily:
- Any new XL-sized unexpected work? → protect sprint goal, defer if possible
- Any tickets blocked? → escalate same day
- Velocity trend: < 70% of target by mid-sprint → identify and remove impediment

## Checklist

- [ ] Team capacity calculated with focus factor
- [ ] Sprint planned to ≤ 70% capacity
- [ ] All XL tickets split before acceptance
- [ ] Dependencies mapped — no accepted ticket has an unknown external block
- [ ] Sprint goal written as a single value statement
- [ ] Carryover from previous sprint accounted for first
