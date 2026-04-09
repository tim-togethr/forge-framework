---
name: react:hooks
description: Custom React hooks — data fetching, cleanup, dependency arrays, and composition
trigger: |
  - Writing logic that needs to be shared across components
  - useEffect with complex dependencies
  - Async data fetching inside components
  - Memory leaks or stale closure warnings
skip_when: |
  - Simple useState or useEffect with no sharing needed
  - Third-party hook (React Query, SWR) already handles the pattern
---

# React Hooks Patterns

## Custom Hook Structure

Every custom hook follows the same shape: extract state + effects, return stable interface.

```tsx
function useUsers(filters: UserFilters) {
  const [data, setData] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function load() {
      setLoading(true);
      setError(null);
      try {
        const users = await fetchUsers(filters);
        if (!cancelled) setData(users);
      } catch (err) {
        if (!cancelled) setError(err instanceof Error ? err : new Error(String(err)));
      } finally {
        if (!cancelled) setLoading(false);
      }
    }

    load();

    return () => {
      cancelled = true; // cleanup prevents state updates on unmounted component
    };
  }, [filters]); // stable dep — see below

  return { data, loading, error };
}
```

## Dependency Array Rules

| Scenario | Rule |
|----------|------|
| Object/array created inline | Memoize with `useMemo` before adding to deps |
| Function called inside effect | Move inside effect OR `useCallback` it |
| Ref value | Refs are stable — omit from deps |
| setState / dispatch | Always stable — omit from deps |
| Props | Always include |
| Derived values | Compute inside effect, don't add source |

```tsx
// BAD — new object on every render causes infinite loop
useEffect(() => { fetchUser(options); }, [{ id, page }]);

// GOOD — stable reference
const options = useMemo(() => ({ id, page }), [id, page]);
useEffect(() => { fetchUser(options); }, [options]);
```

## Cleanup Patterns

```tsx
// Async cancellation
useEffect(() => {
  const controller = new AbortController();
  fetch(url, { signal: controller.signal })
    .then(r => r.json())
    .then(setData)
    .catch(err => { if (err.name !== 'AbortError') setError(err); });
  return () => controller.abort();
}, [url]);

// Subscription cleanup
useEffect(() => {
  const sub = eventBus.subscribe('update', handler);
  return () => sub.unsubscribe();
}, [handler]);

// Timer cleanup
useEffect(() => {
  const id = setInterval(tick, 1000);
  return () => clearInterval(id);
}, []);
```

## Hook Composition

Build complex hooks from simple ones.

```tsx
function useDebounce<T>(value: T, delay: number): T {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const id = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(id);
  }, [value, delay]);
  return debounced;
}

function useSearchUsers(query: string) {
  const debounced = useDebounce(query, 300);
  return useUsers({ search: debounced });
}
```

## Checklist

- [ ] Cleanup function returns from every `useEffect` with subscriptions or async ops
- [ ] Cancelled/unmounted flag prevents state updates after component unmounts
- [ ] Dependency arrays are complete — use exhaustive-deps lint rule
- [ ] Objects/arrays in deps are memoized, not created inline
- [ ] Custom hooks start with `use` prefix
- [ ] Hook returns a stable, typed interface
