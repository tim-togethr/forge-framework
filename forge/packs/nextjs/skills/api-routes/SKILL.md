---
name: nextjs:api-routes
description: Next.js API route handlers — request handling, validation, error responses
trigger: |
  - Creating or modifying API routes in src/app/api/
  - API error handling questions
  - Request validation implementation
skip_when: |
  - External API (not Next.js route handlers)
---

# API Route Handlers

## Structure

```typescript
import { NextRequest, NextResponse } from "next/server";

export async function GET(request: NextRequest) {
  const users = await getUsers();
  return NextResponse.json(users);
}

export async function POST(request: NextRequest) {
  const body = await request.json();
  const parsed = createUserSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Validation failed", details: parsed.error.flatten() },
      { status: 400 }
    );
  }
  const user = await createUser(parsed.data);
  return NextResponse.json(user, { status: 201 });
}
```

## Key Rules

1. **Named exports** — `GET`, `POST`, `PUT`, `DELETE`, `PATCH` (uppercase)
2. **Validate all input** — Use Zod for request body validation
3. **Consistent error format** — `{ error: string, details?: object }`
4. **Status codes** — 200 (OK), 201 (Created), 400 (Bad Request), 401 (Unauthorized), 404 (Not Found), 500 (Server Error)

## Checklist

- [ ] Request body validated with Zod schema
- [ ] Error responses follow `{ error, details }` format
- [ ] Correct HTTP status codes
- [ ] Auth checks where required
- [ ] No server secrets exposed in response
