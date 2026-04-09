---
name: typescript:type-safety
description: TypeScript type safety patterns — strict types, generics, narrowing, branded types
trigger: |
  - Writing new TypeScript interfaces or types
  - Type errors or "any" usage detected
  - User asks about type patterns
skip_when: |
  - JavaScript-only files (no .ts/.tsx)
  - Type definitions already complete and correct
---

# Type Safety Patterns

## Core Rules

1. **No `any`** — Use `unknown` for truly unknown types, then narrow
2. **Strict mode** — `tsconfig.json` must have `"strict": true`
3. **Exhaustive switches** — Use `never` for exhaustiveness checking
4. **Branded types** — Use branded types for domain IDs to prevent mixing

## Narrowing Patterns

```typescript
function processInput(input: unknown): string {
  if (typeof input === "string") return input;
  if (typeof input === "number") return String(input);
  throw new Error(`Unexpected input type: ${typeof input}`);
}

type Result<T> = { ok: true; value: T } | { ok: false; error: string };
```

## Branded Types

```typescript
type UserId = string & { readonly __brand: "UserId" };
type CompanyId = string & { readonly __brand: "CompanyId" };

function createUserId(id: string): UserId { return id as UserId; }
```

## Checklist

- [ ] No `any` in changed files
- [ ] All switch statements have `default: never` exhaustiveness
- [ ] API response types match actual response shapes
- [ ] Utility types used where appropriate (`Partial`, `Pick`, `Omit`)
