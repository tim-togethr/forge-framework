---
name: leadership:architecture-decisions
description: ADR format — evaluate 2+ alternatives, explicit tradeoffs, risks with mitigations
trigger: |
  - Choosing between technical approaches with long-term impact
  - Selecting a new technology, library, or vendor
  - Changing a core architectural pattern
  - Decision that will be hard to reverse
skip_when: |
  - Tactical implementation choice with easy reversal path
  - Standard pattern already established in the codebase
---

# Architecture Decision Records

## When to Write an ADR

Write an ADR when:
- The decision affects more than one team or system boundary
- Reversing the decision would cost >1 sprint
- Multiple reasonable options exist and the choice is non-obvious
- Future team members will ask "why did we do it this way?"

## ADR Template

```markdown
# ADR-[NNN]: [Title — decision being made]

**Date**: YYYY-MM-DD
**Status**: Proposed | Accepted | Superseded by ADR-XXX
**Deciders**: [Names/roles]

## Context

[2-4 sentences: what problem are we solving, what constraints exist,
why does this decision need to be made now]

## Decision Drivers

- [Most important factor]
- [Second factor]
- [Third factor — usually team capability or operational complexity]

## Options Considered

### Option A: [Name]
[2-3 sentence description]

**Pros**:
- [Concrete benefit]
- [Concrete benefit]

**Cons**:
- [Concrete cost or risk]
- [Concrete cost or risk]

### Option B: [Name]
[description]

**Pros**: ...
**Cons**: ...

### Option C: [Name — often "do nothing"]
[description]

**Pros**: ...
**Cons**: ...

## Decision

**Chosen option: [A/B/C] — [Name]**

[2-3 sentences explaining why this option best satisfies the decision drivers
given the current context and constraints]

## Consequences

**Positive**:
- [What improves]

**Negative**:
- [Technical debt or tradeoff accepted]

**Risks and Mitigations**:
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk] | Low/Med/High | Low/Med/High | [How we'll address it] |

## Review Date
[When to revisit this decision, e.g., "After 3 months in production" or "When team grows past 10 engineers"]
```

## Evaluation Framework

Rate each option against the decision drivers (1-5):

| Criterion | Option A | Option B | Option C |
|-----------|----------|----------|----------|
| Operational simplicity | 4 | 2 | 5 |
| Scalability to 10x load | 2 | 5 | 2 |
| Team familiarity | 5 | 3 | 5 |
| Cost | 4 | 3 | 5 |
| **Weighted total** | **15** | **13** | **17** |

Weight the criteria by importance before scoring.

## Anti-Patterns

- Writing an ADR after the decision is already implemented (post-hoc rationalization)
- Only considering one option
- Listing risks without mitigations
- Ignoring team capability as a factor
- Choosing "best technology" over "best fit for our context"

## Checklist

- [ ] At least 2 alternatives evaluated (including "do nothing")
- [ ] Pros and cons are specific, not generic ("scales better" → "handles 10x load without infra changes")
- [ ] Decision drivers made explicit before scoring
- [ ] Every risk has a mitigation
- [ ] Review date set
- [ ] ADR stored in `docs/adr/` and linked from relevant code or README
