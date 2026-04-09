---
name: nextjs:server-components
description: React Server Components — data fetching, streaming, client/server boundaries
trigger: |
  - Data fetching in components
  - "use client" boundary decisions
  - Streaming or Suspense implementation
skip_when: |
  - Pure client-side SPA (no server rendering)
---

# Server Components

## Key Rules

1. **Server by default** — All components in App Router are Server Components unless marked `"use client"`
2. **No hooks in SC** — `useState`, `useEffect`, etc. are client-only
3. **Fetch in SC** — Data fetching belongs in Server Components, not in `useEffect`
4. **Push client boundary down** — Only the interactive leaf needs `"use client"`, not the whole tree

## Data Fetching

```typescript
export default async function DashboardPage() {
  const data = await fetch("https://api.example.com/stats");
  const stats = await data.json();
  return <StatsDisplay stats={stats} />;
}
```

## Client Boundary

```typescript
"use client";
export function LikeButton({ postId }: { postId: string }) {
  const [liked, setLiked] = useState(false);
  return <button onClick={() => setLiked(!liked)}>Like</button>;
}

export default async function PostPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const post = await getPost(id);
  return (
    <article>
      <h1>{post.title}</h1>
      <p>{post.body}</p>
      <LikeButton postId={id} />
    </article>
  );
}
```

## Checklist

- [ ] Data fetching happens in Server Components (not useEffect)
- [ ] `"use client"` only on components that need interactivity
- [ ] No server-only imports (DB clients, secrets) in client components
- [ ] Suspense boundaries around async Server Components for streaming
