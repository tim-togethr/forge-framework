---
name: golang:concurrency
description: Go concurrency — pass context, bounded goroutines, close from sender, errgroup pattern
trigger: |
  - Launching goroutines
  - Writing concurrent data processing
  - HTTP handlers that fan out requests
  - Cancellation and timeout propagation
skip_when: |
  - Single-goroutine code path with no concurrency
---

# Go Concurrency Patterns

## Always Pass Context

Context is the first parameter. Propagate it everywhere — don't use `context.Background()` inside a function that received a context.

```go
// BAD — ignores cancellation
func processItems(items []Item) error {
    for _, item := range items {
        if err := process(context.Background(), item); err != nil {
            return err
        }
    }
    return nil
}

// GOOD — respects caller's cancellation/deadline
func processItems(ctx context.Context, items []Item) error {
    for _, item := range items {
        if err := ctx.Err(); err != nil {
            return fmt.Errorf("processItems cancelled: %w", err)
        }
        if err := process(ctx, item); err != nil {
            return fmt.Errorf("processing item %s: %w", item.ID, err)
        }
    }
    return nil
}
```

## Bounded Goroutines with errgroup

Use `golang.org/x/sync/errgroup` for structured concurrency. Never launch unbounded goroutines.

```go
import "golang.org/x/sync/errgroup"

func fetchAll(ctx context.Context, ids []string) ([]User, error) {
    g, ctx := errgroup.WithContext(ctx)
    results := make([]User, len(ids))

    // Semaphore to bound concurrency
    sem := make(chan struct{}, 10) // max 10 concurrent

    for i, id := range ids {
        i, id := i, id // capture loop variables
        g.Go(func() error {
            sem <- struct{}{}
            defer func() { <-sem }()

            user, err := fetchUser(ctx, id)
            if err != nil {
                return fmt.Errorf("fetching user %s: %w", id, err)
            }
            results[i] = user
            return nil
        })
    }

    if err := g.Wait(); err != nil {
        return nil, err
    }
    return results, nil
}
```

## Close Channels from the Sender

Only the goroutine writing to a channel should close it. Closing from a receiver causes panics.

```go
func produce(ctx context.Context) <-chan int {
    ch := make(chan int)
    go func() {
        defer close(ch) // sender closes
        for i := 0; ; i++ {
            select {
            case <-ctx.Done():
                return
            case ch <- i:
            }
        }
    }()
    return ch
}

func consume(ctx context.Context, ch <-chan int) {
    for {
        select {
        case <-ctx.Done():
            return
        case v, ok := <-ch:
            if !ok {
                return // channel closed
            }
            process(v)
        }
    }
}
```

## Avoiding Data Races

```go
// BAD — concurrent map writes
var cache = map[string]string{}
go func() { cache["key"] = "value" }()  // RACE

// GOOD — sync.Map or mutex
var mu sync.RWMutex
var cache = map[string]string{}

func set(k, v string) {
    mu.Lock()
    defer mu.Unlock()
    cache[k] = v
}

func get(k string) (string, bool) {
    mu.RLock()
    defer mu.RUnlock()
    v, ok := cache[k]
    return v, ok
}
```

## Goroutine Leak Prevention

```go
// Always ensure goroutines exit when context is cancelled
func worker(ctx context.Context, jobs <-chan Job) {
    for {
        select {
        case <-ctx.Done():
            return // guaranteed exit
        case job, ok := <-jobs:
            if !ok {
                return // channel closed
            }
            handle(ctx, job)
        }
    }
}
```

## Checklist

- [ ] `context.Context` is first parameter in all exported functions
- [ ] Context checked (`ctx.Err()`) in long loops
- [ ] Goroutines bounded with semaphore or `errgroup` with limit
- [ ] Loop variables captured before goroutine launch (`i, v := i, v`)
- [ ] Channels closed only by the sender
- [ ] `go test -race` passes
- [ ] All goroutines have a guaranteed exit path
