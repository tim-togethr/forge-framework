---
name: typescript:strict-mode
description: TypeScript strict configuration — compiler options and project setup
trigger: |
  - New TypeScript project setup
  - tsconfig.json modifications
  - Build errors related to strict mode
skip_when: |
  - tsconfig.json already has strict: true and project builds clean
---

# TypeScript Strict Mode

## Required tsconfig.json Settings

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "forceConsistentCasingInFileNames": true
  }
}
```

## What `strict: true` Enables

| Flag | What It Catches |
|------|-----------------|
| `strictNullChecks` | `null` and `undefined` not assignable to other types |
| `strictFunctionTypes` | Contravariant parameter checking |
| `strictBindCallApply` | Correct types for `bind`, `call`, `apply` |
| `strictPropertyInitialization` | Class properties must be initialized |
| `noImplicitAny` | Must declare types, no implicit `any` |
| `noImplicitThis` | `this` must have explicit type in functions |
| `alwaysStrict` | Emit `"use strict"` in all files |

## Checklist

- [ ] `strict: true` in tsconfig.json
- [ ] `noUncheckedIndexedAccess: true` for safe array/object access
- [ ] No `// @ts-ignore` or `// @ts-expect-error` without explanation
