---
name: python:pythonic-patterns
description: Python idioms — type hints, dataclasses, context managers, comprehensions, project structure
trigger: |
  - Writing new Python modules or classes
  - Data structures passed between functions
  - File/network/resource management
  - Collection transformations
skip_when: |
  - Rapid script with no intent to reuse or maintain
  - Existing codebase uses a different documented style
---

# Pythonic Patterns

## Type Hints Everywhere

All function signatures and class attributes must have type hints. Use `from __future__ import annotations` for forward references.

```python
from __future__ import annotations
from typing import Optional, Sequence

def get_user(user_id: str, *, active_only: bool = True) -> Optional[User]:
    """Return user by ID, or None if not found."""
    ...

def process_items(items: Sequence[Item]) -> list[ProcessedItem]:
    ...
```

## Dataclasses Over Dicts

Replace `dict` return values and ad-hoc data bundles with typed dataclasses.

```python
# BAD — untyped dict, no autocomplete, no validation
def get_config() -> dict:
    return {"host": "localhost", "port": 5432, "ssl": True}

# GOOD — typed, auto-__init__, auto-__repr__, IDE support
from dataclasses import dataclass, field

@dataclass(frozen=True)  # immutable config
class DatabaseConfig:
    host: str
    port: int = 5432
    ssl: bool = True
    options: dict[str, str] = field(default_factory=dict)

# For complex validation, prefer pydantic BaseModel
from pydantic import BaseModel, validator

class UserCreate(BaseModel):
    email: str
    name: str
    age: int

    @validator('age')
    def age_must_be_positive(cls, v: int) -> int:
        if v < 0:
            raise ValueError('age must be positive')
        return v
```

## Context Managers for Resources

Always use `with` for anything that needs cleanup: files, connections, locks, temporary state.

```python
# BAD — resource leak if exception occurs
f = open("data.csv")
content = f.read()
f.close()

# GOOD — guaranteed close
with open("data.csv", encoding="utf-8") as f:
    content = f.read()

# Custom context manager
from contextlib import contextmanager

@contextmanager
def temporary_directory():
    tmpdir = tempfile.mkdtemp()
    try:
        yield Path(tmpdir)
    finally:
        shutil.rmtree(tmpdir, ignore_errors=True)

with temporary_directory() as tmpdir:
    process_files(tmpdir)
```

## Comprehensions and Generator Expressions

Prefer comprehensions over explicit loops for transformations. Use generators for large sequences.

```python
# List comprehension — eagerly evaluated
active_emails = [user.email for user in users if user.is_active]

# Dict comprehension
id_to_user = {user.id: user for user in users}

# Generator — lazy, memory-efficient for large sequences
total = sum(item.price * item.qty for item in order.items)

# Avoid nested comprehensions beyond 2 levels — use a function
# BAD
flat = [cell for row in matrix for cell in row if cell > 0]

# GOOD — named function for complex logic
def positive_cells(matrix: list[list[int]]) -> list[int]:
    return [cell for row in matrix for cell in row if cell > 0]
```

## Project Structure

```
my_project/
├── src/
│   └── my_project/
│       ├── __init__.py
│       ├── models.py      # dataclasses / pydantic models
│       ├── services.py    # business logic
│       ├── repositories.py # data access
│       └── api/
│           └── routes.py
├── tests/
│   ├── conftest.py        # shared fixtures
│   └── test_services.py
├── pyproject.toml         # single config file (replaces setup.py + setup.cfg)
└── README.md
```

## pyproject.toml (modern packaging)

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "my-project"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = ["pydantic>=2.0", "httpx>=0.27"]

[project.optional-dependencies]
dev = ["pytest", "ruff", "mypy"]

[tool.ruff]
select = ["E", "F", "I", "UP", "B"]
line-length = 100

[tool.mypy]
strict = true
```

## Checklist

- [ ] All function signatures have type hints (params + return)
- [ ] Data bundles use `@dataclass` or `pydantic.BaseModel`, not `dict`
- [ ] Resources managed with `with` statements
- [ ] Comprehensions used for simple transforms (no side effects)
- [ ] `pyproject.toml` used (not `setup.py`)
- [ ] `ruff` or `flake8` passes with no errors
- [ ] `mypy --strict` passes (or target is documented)
