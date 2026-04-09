---
name: planning:brainstorming
description: Brainstorming flow — explore context, ask one question at a time, propose 2-3 approaches, present design, write doc, hand off
trigger: |
  - User asks to brainstorm, explore, or think through a feature/problem
  - Ambiguous requirements where multiple approaches exist
  - Starting a new feature before writing any code
  - Design decisions with significant tradeoffs
skip_when: |
  - Requirements are already clear and a plan exists
  - Small change (< 1 hour) with obvious implementation
---

# Brainstorming Flow

## The 5-Phase Process

### Phase 1: Explore Context (Silent)

Before asking anything, read the codebase to understand:
- What already exists that's relevant
- Patterns already in use
- Constraints (auth model, data model, API patterns)

**Do not ask questions about things you can find by reading.**

### Phase 2: Ask Clarifying Questions — One at a Time

Ask the single most important question. Wait for the answer. Then ask the next.

```
You: "What's the primary user goal — are they trying to track progress over time,
      or get a one-time snapshot of their status?"

User: "Track over time"

You: "How often do they expect to check this — daily, weekly, or on-demand?"
```

**Never fire a list of 5+ questions.** It signals you haven't thought about what actually matters.

Common question patterns:
- "Who is the primary user of this feature, and what's the one thing they need to do?"
- "What does success look like — how will we know this works?"
- "What's the biggest risk or concern about this approach?"
- "Are there constraints I should know about (deadlines, tech, team capability)?"

### Phase 3: Propose 2-3 Approaches

Present distinct approaches with explicit tradeoffs. Don't pick a winner yet.

```
## Approach A: [Name]
**How it works**: ...
**Pros**: fast to build, fits existing patterns
**Cons**: doesn't scale beyond 1000 users

## Approach B: [Name]
**How it works**: ...
**Pros**: scalable, future-proof
**Cons**: 3x more complex, requires schema migration

## Approach C: [Name]
**How it works**: ...
**Pros**: minimal change
**Cons**: technical debt, workaround not a solution

**My recommendation**: B — because [specific reason tied to their constraints].
```

### Phase 4: Present Design

Once an approach is chosen, present the full design:
- Data model changes (if any)
- API shape
- Component tree (if UI)
- Key edge cases and how they're handled
- What's explicitly out of scope

Get sign-off before writing any code.

### Phase 5: Write Design Doc + Handoff

Produce a concise plan document:
- Problem statement (1-2 sentences)
- Chosen approach and rationale
- Implementation steps (broken down — see `planning:writing-plans`)
- Open questions (if any)
- Success criteria

## Anti-Patterns

- Starting to code before the design is agreed
- Asking all questions at once
- Presenting only one option (forces yes/no, not real collaboration)
- Proposing the technically "pure" solution without considering team constraints
- Writing a 10-page doc when a 1-page summary would do

## Checklist

- [ ] Read relevant code before asking questions
- [ ] Asked questions one at a time
- [ ] Presented 2-3 distinct approaches with tradeoffs
- [ ] Made a recommendation with rationale
- [ ] Got explicit sign-off on the chosen approach
- [ ] Produced a written plan before coding
