---
name: supabase:schema-design
description: Supabase schema design — JOINs over duplication, FK to lookup tables, minimal migrations
trigger: |
  - Creating new tables or columns
  - Storing data that might exist elsewhere
  - Writing new migration files
  - Category or lookup data being stored as strings
skip_when: |
  - Schema already reviewed and matches single-source-of-truth principle
  - Simple MVP with no existing lookup tables
---

# Supabase Schema Design

## Core Principle: Single Source of Truth

Every canonical value lives in exactly one table. Never duplicate data that can be JOINed.

```sql
-- BAD: category name stored as string on the product
CREATE TABLE products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  category text NOT NULL  -- "Electronics", "Clothing" — duplicated everywhere
);

-- GOOD: FK to a lookup table
CREATE TABLE categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text UNIQUE NOT NULL,
  name text NOT NULL
);

CREATE TABLE products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  category_id uuid NOT NULL REFERENCES categories(id)
);
```

## Schema-First Checklist (Before Any Migration)

1. **Search existing tables** — Does this data already exist somewhere?
2. **Look for junction tables** — Many-to-many? Use a junction, not an array column.
3. **Check for FK opportunities** — String enum? Should be a FK to a lookup table.
4. **Minimal surface** — Can you add a column to an existing table instead of a new table?

## Migration Best Practices

```sql
-- Always idempotent
CREATE TABLE IF NOT EXISTS user_preferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  theme text NOT NULL DEFAULT 'system',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Indexes on FK columns and common query fields
CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id
  ON user_preferences(user_id);

-- Updated_at trigger
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER user_preferences_updated_at
  BEFORE UPDATE ON user_preferences
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
```

## Junction Tables for Many-to-Many

```sql
-- DON'T store arrays of IDs
-- BAD: tags text[] on articles

-- DO use a junction table
CREATE TABLE article_tags (
  article_id uuid NOT NULL REFERENCES articles(id) ON DELETE CASCADE,
  tag_id uuid NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
  PRIMARY KEY (article_id, tag_id)
);
```

## Test Migrations Locally First

```bash
# Always test locally before pushing
npx supabase db reset   # applies all migrations from scratch
npx supabase db diff    # see what would change

# Never run migrations directly on production
# Use: supabase db push (after local validation)
```

## Checklist

- [ ] Searched existing schema before creating new table
- [ ] Category/enum values reference a lookup table (not bare strings)
- [ ] FK columns have indexes
- [ ] `ON DELETE CASCADE` or `ON DELETE RESTRICT` explicitly set
- [ ] Migration is idempotent (`IF NOT EXISTS`)
- [ ] `updated_at` trigger added for mutable rows
- [ ] Tested locally with `supabase db reset`
