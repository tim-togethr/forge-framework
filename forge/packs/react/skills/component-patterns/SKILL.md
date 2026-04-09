---
name: react:component-patterns
description: React component design — composition, single responsibility, memoization, compound components
trigger: |
  - Creating new React components
  - Component feels too large or does too many things
  - Props are being drilled more than 2 levels deep
  - Performance complaints about re-renders
skip_when: |
  - Simple presentational component with no state
  - One-off utility component that won't be reused
---

# React Component Patterns

## Core Principles

### 1. Composition Over Configuration

Prefer composing small, focused components over a single component with many boolean props.

```tsx
// BAD — boolean prop explosion
<Modal
  showHeader
  showFooter
  showCloseButton
  title="Settings"
  footerContent={<Button>Save</Button>}
/>

// GOOD — composition
<Modal>
  <Modal.Header>Settings</Modal.Header>
  <Modal.Body>{children}</Modal.Body>
  <Modal.Footer>
    <Button>Save</Button>
  </Modal.Footer>
</Modal>
```

### 2. Single Responsibility

Each component should do one thing. If you need the word "and" to describe it, split it.

```tsx
// BAD — fetches + filters + renders
function UserList() {
  const users = useFetchUsers();
  const filtered = users.filter(u => u.active);
  return filtered.map(u => <UserRow key={u.id} user={u} />);
}

// GOOD — separate concerns
function UserListContainer() {
  const users = useFetchUsers();
  return <UserList users={users} />;
}

function UserList({ users }: { users: User[] }) {
  const active = users.filter(u => u.active);
  return active.map(u => <UserRow key={u.id} user={u} />);
}
```

### 3. Memoization — Only When Measured

Don't memoize speculatively. Profile first, then apply.

```tsx
// Use React.memo only when parent re-renders frequently and child is expensive
const ExpensiveChart = React.memo(function Chart({ data }: ChartProps) {
  return <canvas>{/* heavy rendering */}</canvas>;
});

// useMemo for expensive computations
const sortedUsers = useMemo(
  () => [...users].sort((a, b) => a.name.localeCompare(b.name)),
  [users]
);

// useCallback for stable function references passed to memoized children
const handleDelete = useCallback(
  (id: string) => dispatch({ type: 'DELETE', id }),
  [dispatch]
);
```

### 4. Compound Component Pattern

For complex UI that shares implicit state (tabs, accordions, selects).

```tsx
interface TabsContextValue {
  active: string;
  setActive: (id: string) => void;
}

const TabsContext = createContext<TabsContextValue | null>(null);

function Tabs({ defaultTab, children }: TabsProps) {
  const [active, setActive] = useState(defaultTab);
  return (
    <TabsContext.Provider value={{ active, setActive }}>
      <div className="tabs">{children}</div>
    </TabsContext.Provider>
  );
}

function Tab({ id, children }: TabProps) {
  const ctx = useContext(TabsContext);
  if (!ctx) throw new Error('Tab must be used inside Tabs');
  return (
    <button
      className={ctx.active === id ? 'active' : ''}
      onClick={() => ctx.setActive(id)}
    >
      {children}
    </button>
  );
}

Tabs.Tab = Tab;

// Usage
<Tabs defaultTab="profile">
  <Tabs.Tab id="profile">Profile</Tabs.Tab>
  <Tabs.Tab id="settings">Settings</Tabs.Tab>
</Tabs>
```

## Checklist

- [ ] Component has a single, clear purpose
- [ ] Props interface is defined with TypeScript
- [ ] No prop drilling beyond 2 levels (use context or composition)
- [ ] `key` prop is a stable ID, not array index
- [ ] `React.memo` / `useMemo` / `useCallback` only added after profiling
- [ ] Compound components use Context, not prop-threading
