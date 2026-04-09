---
name: golang:error-handling
description: Go error handling — always check errors, wrap with %w, sentinel errors, errors.Is/As
trigger: |
  - Writing any function that returns an error
  - Propagating errors up the call stack
  - Defining package-level error types
  - Checking for specific error conditions
skip_when: |
  - Error is already correctly wrapped and checked in the surrounding code
---

# Go Error Handling

## Always Check Errors

Never discard an error value. No `_` on the error return unless you have a documented reason.

```go
// BAD
data, _ := os.ReadFile("config.json")

// GOOD
data, err := os.ReadFile("config.json")
if err != nil {
    return fmt.Errorf("reading config: %w", err)
}
```

## Wrapping with %w

Wrap errors with context at each layer so callers can understand the chain.

```go
func loadUser(id string) (*User, error) {
    row, err := db.QueryRow("SELECT * FROM users WHERE id = $1", id)
    if err != nil {
        return nil, fmt.Errorf("loadUser %s: %w", id, err)
    }
    // ...
}

// Caller sees: "loadUser abc-123: sql: no rows in result set"
```

**Rule**: Add context that isn't already in the wrapped error. Don't write `fmt.Errorf("error: %w", err)`.

## Sentinel Errors

Define package-level sentinels for conditions callers need to distinguish.

```go
// errors.go in your package
var (
    ErrNotFound   = errors.New("not found")
    ErrUnauthorized = errors.New("unauthorized")
)

func GetUser(id string) (*User, error) {
    user, ok := store[id]
    if !ok {
        return nil, fmt.Errorf("user %s: %w", id, ErrNotFound)
    }
    return user, nil
}

// Caller can check specifically
err := GetUser(id)
if errors.Is(err, ErrNotFound) {
    http.Error(w, "not found", http.StatusNotFound)
    return
}
```

## errors.Is and errors.As

```go
// errors.Is — checks for a sentinel anywhere in the chain
if errors.Is(err, sql.ErrNoRows) {
    return nil, ErrNotFound
}

// errors.As — extracts a concrete type from the chain
var pgErr *pgconn.PgError
if errors.As(err, &pgErr) {
    if pgErr.Code == "23505" {
        return nil, ErrAlreadyExists
    }
}

// NEVER use string comparison
if err.Error() == "not found" { ... }  // BAD — breaks with wrapping
```

## Error Types for Rich Context

Use structs when callers need fields, not just a message.

```go
type ValidationError struct {
    Field   string
    Message string
}

func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation error: %s — %s", e.Field, e.Message)
}

// Caller extracts structured data
var valErr *ValidationError
if errors.As(err, &valErr) {
    respondJSON(w, map[string]string{"field": valErr.Field, "error": valErr.Message})
}
```

## Checklist

- [ ] Every error return is checked immediately
- [ ] Errors wrapped with `fmt.Errorf("context: %w", err)`
- [ ] Sentinel errors defined for distinguishable conditions
- [ ] `errors.Is` / `errors.As` used (not string comparison)
- [ ] No `panic` for expected error conditions
- [ ] `log.Fatal` only at `main()` level, never in libraries
