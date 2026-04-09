---
name: nextjs:app-router
description: Next.js App Router patterns — layouts, loading states, error boundaries, parallel routes
trigger: |
  - Creating new pages or routes in src/app/
  - Route organization questions
  - Layout or loading state implementation
skip_when: |
  - Pages Router project (no src/app/ directory)
---

# App Router Patterns

## Route Structure

```
src/app/
├── layout.tsx          # Root layout (required)
├── page.tsx            # Home page
├── loading.tsx         # Loading UI (Suspense boundary)
├── error.tsx           # Error boundary
├── not-found.tsx       # 404 page
├── dashboard/
│   ├── layout.tsx      # Dashboard layout (nested)
│   ├── page.tsx        # /dashboard
│   └── settings/
│       └── page.tsx    # /dashboard/settings
└── api/
    └── route.ts        # API route handler
```

## Key Rules

1. **Layouts persist** — they don't re-render on navigation. Put shared UI here.
2. **`page.tsx` is required** — a directory is only a route if it has `page.tsx`
3. **Loading states** — `loading.tsx` auto-wraps `page.tsx` in Suspense
4. **Error boundaries** — `error.tsx` must be a client component (`"use client"`)
5. **Metadata** — export `metadata` object or `generateMetadata()` function from `page.tsx` or `layout.tsx`

## Dynamic Routes

```typescript
export default async function UserPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const user = await getUser(id);
  return <UserProfile user={user} />;
}
```

## Checklist

- [ ] Every route directory has a `page.tsx`
- [ ] Layouts don't fetch user-specific data
- [ ] Dynamic params awaited (Next.js 15+ requirement)
- [ ] Error boundaries are client components
- [ ] Loading states exist for data-fetching pages
