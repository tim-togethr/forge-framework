---
name: planning:writing-plans
description: Writing implementation plans — 2-5 min tasks, exact file paths, complete code, TDD, no placeholders
trigger: |
  - Writing a plan for implementation
  - Breaking down a feature into tasks
  - Creating a spec for another developer (or AI agent) to execute
skip_when: |
  - Trivial single-file change requiring no planning
---

# Writing Implementation Plans

## Core Principle

A good plan is executable. Someone (or an AI agent) should be able to follow it step by step with no ambiguity.

## Task Sizing

Break work into 2-5 minute tasks. If a task takes longer, split it.

```
BAD:
- [ ] Implement the user authentication system

GOOD:
- [ ] Create src/lib/auth/session.ts — SessionManager class with create(), validate(), destroy() methods
- [ ] Add /api/auth/login POST route — validates credentials, creates session, returns 200 or 401
- [ ] Add /api/auth/logout POST route — destroys session, clears cookie
- [ ] Add AuthMiddleware to src/middleware.ts — checks session on all /api/protected/* routes
- [ ] Write tests for SessionManager in src/lib/auth/session.test.ts
```

## Exact File Paths

Every task that touches a file must name the exact path.

```
BAD:  "Create a new component for the user profile"
GOOD: "Create src/components/user/UserProfileCard.tsx"

BAD:  "Add a database migration"
GOOD: "Create supabase/migrations/20260409120000_add_user_preferences.sql"
```

## Complete Code in Plans

Include complete code snippets, not stubs. A plan with `// TODO: implement` in it is not a plan.

```typescript
// Task: Create src/lib/auth/tokens.ts
// Include the full implementation in the plan:
import { randomBytes, createHmac } from 'crypto';

export function generateToken(length = 32): string {
  return randomBytes(length).toString('hex');
}

export function signToken(token: string, secret: string): string {
  return createHmac('sha256', secret).update(token).digest('hex');
}
```

## TDD Order

Write tests before implementation. Plan in this order:

1. Write failing test
2. Write implementation to make it pass
3. Refactor

```
Plan order:
- [ ] src/lib/pricing.test.ts — test calculateDiscount() with 3 cases
- [ ] src/lib/pricing.ts — implement calculateDiscount() to pass tests
- [ ] src/lib/pricing.ts — refactor: extract discount table to constants
```

## No Placeholders

These are banned in plans:

- `// TODO`
- `// implement later`
- `[INSERT_LOGIC_HERE]`
- `/* ... */`
- `pass` (Python)
- `return nil // stub`

If you don't know how to implement something, say so explicitly and resolve it before writing the plan.

## Plan Template

```markdown
## Goal
[1-2 sentence problem statement]

## Approach
[Chosen approach from brainstorm — 2-3 sentences]

## Implementation Steps

### 1. Data Layer
- [ ] `supabase/migrations/YYYYMMDDHHMMSS_description.sql` — [what it does]
- [ ] `src/types/user.ts` — add `UserPreferences` type

### 2. API
- [ ] `src/app/api/preferences/route.ts` — GET (fetch), POST (upsert)

### 3. UI
- [ ] `src/components/settings/PreferencesForm.tsx` — form with useForm hook

### 4. Tests
- [ ] `src/app/api/preferences/route.test.ts` — 4 cases: valid GET, valid POST, unauthenticated, invalid body

## Out of Scope
- [Explicitly list what is NOT being built]

## Success Criteria
- [ ] Preferences persisted to DB and retrieved correctly
- [ ] All tests pass
- [ ] No TypeScript errors
- [ ] `npm run build` succeeds
```

## Checklist

- [ ] Every task fits in 2-5 minutes
- [ ] Every file reference is an exact path from repo root
- [ ] No placeholder code (`// TODO`, stubs, `pass`)
- [ ] Tests written before implementation in the task order
- [ ] "Out of scope" section explicitly names exclusions
- [ ] Success criteria are verifiable (tests pass, build succeeds)
