---
name: supabase:rls-policies
description: Row-Level Security — enable on every user-facing table, separate policies per operation, service role server-only
trigger: |
  - Creating a new table that users will access
  - Writing SELECT/INSERT/UPDATE/DELETE policies
  - Server-side vs client-side Supabase client questions
  - Security audit of database access patterns
skip_when: |
  - Table is internal-only and never accessed by anon/authenticated roles
  - RLS already enabled and policies already reviewed
---

# Supabase RLS Policies

## The Golden Rule

**RLS on every table that authenticated or anonymous users can reach.** No exceptions.

```sql
-- Enable on table creation
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles FORCE ROW LEVEL SECURITY;
```

## Policy Per Operation

Write separate policies for SELECT, INSERT, UPDATE, DELETE. Never combine unless the logic is identical.

```sql
-- SELECT: users see only their own profile
CREATE POLICY "users_select_own_profile"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- INSERT: users can create their own profile
CREATE POLICY "users_insert_own_profile"
  ON user_profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- UPDATE: users can update their own profile
CREATE POLICY "users_update_own_profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- DELETE: users cannot delete (admin only via service role)
-- Omit DELETE policy — no policy = no access
```

## Multi-Tenant Patterns

```sql
-- Organisation-scoped access
CREATE POLICY "org_members_select"
  ON documents FOR SELECT
  TO authenticated
  USING (
    org_id IN (
      SELECT org_id FROM org_memberships
      WHERE user_id = auth.uid()
    )
  );
```

## Service Role: Server-Side Only

```typescript
// NEVER expose service role key to the browser
// Service role bypasses RLS — treat like a root password

// server-side only (API routes, server components, middleware)
import { createClient } from '@supabase/supabase-js';

const adminClient = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!  // NOT NEXT_PUBLIC_
);

// client-side: always use anon key
import { createBrowserClient } from '@supabase/ssr';
const client = createBrowserClient(url, anonKey);
```

## Preventing Recursive RLS

```sql
-- BAD: policy queries the same table it's protecting → infinite recursion
CREATE POLICY "members_select"
  ON org_memberships FOR SELECT
  USING (user_id IN (SELECT user_id FROM org_memberships WHERE org_id = org_id));

-- GOOD: use auth.uid() directly or a separate junction table
CREATE POLICY "members_select_own"
  ON org_memberships FOR SELECT
  USING (user_id = auth.uid());
```

## Checklist

- [ ] `ALTER TABLE ... ENABLE ROW LEVEL SECURITY` on every user-facing table
- [ ] Separate policies for SELECT, INSERT, UPDATE, DELETE
- [ ] `USING` clause on SELECT/UPDATE/DELETE; `WITH CHECK` on INSERT/UPDATE
- [ ] `SUPABASE_SERVICE_ROLE_KEY` never in `NEXT_PUBLIC_` variables
- [ ] Service role client only instantiated in server-side code
- [ ] No recursive RLS (policy doesn't query its own table)
- [ ] Admin bypass documented and auditable
