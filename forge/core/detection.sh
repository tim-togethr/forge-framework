#!/usr/bin/env bash
# Forge Detection Engine
# Scans a repo directory and outputs JSON array of activated pack names.
# Usage: detection.sh /path/to/repo
set -euo pipefail

REPO_DIR="${1:-.}"
FORGE_DIR="$REPO_DIR/.forge"
DETECTED=()

# --- File-based detection ---

# nextjs
if ls "$REPO_DIR"/next.config.* 1>/dev/null 2>&1 || \
   ( [ -d "$REPO_DIR/src/app" ] && \
     [ -f "$REPO_DIR/package.json" ] && \
     grep -q '"next"' "$REPO_DIR/package.json" 2>/dev/null ); then
  DETECTED+=("nextjs")
fi

# react (check package.json deps)
if [ -f "$REPO_DIR/package.json" ] && grep -q '"react"' "$REPO_DIR/package.json" 2>/dev/null; then
  DETECTED+=("react")
fi

# supabase
if [ -f "$REPO_DIR/supabase/config.toml" ] || \
   [ -d "$REPO_DIR/supabase/migrations" ] || \
   ([ -f "$REPO_DIR/package.json" ] && grep -q '@supabase/supabase-js' "$REPO_DIR/package.json" 2>/dev/null); then
  DETECTED+=("supabase")
fi

# tailwind
if ls "$REPO_DIR"/tailwind.config.* 1>/dev/null 2>&1 || \
   ([ -f "$REPO_DIR/package.json" ] && grep -q '"tailwindcss"' "$REPO_DIR/package.json" 2>/dev/null); then
  DETECTED+=("tailwind")
fi

# typescript
if [ -f "$REPO_DIR/tsconfig.json" ] || \
   ([ -f "$REPO_DIR/package.json" ] && grep -q '"typescript"' "$REPO_DIR/package.json" 2>/dev/null); then
  DETECTED+=("typescript")
fi

# golang
if [ -f "$REPO_DIR/go.mod" ]; then
  DETECTED+=("golang")
fi

# python
if [ -f "$REPO_DIR/pyproject.toml" ] || \
   [ -f "$REPO_DIR/requirements.txt" ] || \
   [ -f "$REPO_DIR/setup.py" ]; then
  DETECTED+=("python")
fi

# docker
if [ -f "$REPO_DIR/Dockerfile" ] || \
   ls "$REPO_DIR"/docker-compose.* 1>/dev/null 2>&1; then
  DETECTED+=("docker")
fi

# --- forge.yaml overrides ---

if [ -f "$FORGE_DIR/forge.yaml" ]; then
  # Add extra_packs — extract list items under the extra_packs: key
  if grep -q '^extra_packs:' "$FORGE_DIR/forge.yaml" 2>/dev/null; then
    while IFS= read -r line; do
      pack=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*//' | sed 's/[[:space:]]*#.*//' | tr -d '[:space:]')
      if [ -n "$pack" ] && [[ ! " ${DETECTED[*]:-} " =~ " $pack " ]]; then
        DETECTED+=("$pack")
      fi
    done < <(awk '/^extra_packs:/{found=1; next} found && /^  *-/{print; next} found && /^[^[:space:]]/{exit}' "$FORGE_DIR/forge.yaml")
  fi

  # Remove suppress_packs — extract list items under the suppress_packs: key
  if grep -q '^suppress_packs:' "$FORGE_DIR/forge.yaml" 2>/dev/null; then
    SUPPRESSED=()
    while IFS= read -r line; do
      pack=$(echo "$line" | sed 's/^[[:space:]]*-[[:space:]]*//' | sed 's/[[:space:]]*#.*//' | tr -d '[:space:]')
      [ -n "$pack" ] && SUPPRESSED+=("$pack")
    done < <(awk '/^suppress_packs:/{found=1; next} found && /^  *-/{print; next} found && /^[^[:space:]]/{exit}' "$FORGE_DIR/forge.yaml")

    FILTERED=()
    for pack in "${DETECTED[@]}"; do
      if [[ ! " ${SUPPRESSED[*]:-} " =~ " $pack " ]]; then
        FILTERED+=("$pack")
      fi
    done
    DETECTED=(${FILTERED[@]+"${FILTERED[@]}"})
  fi
fi

# --- Output JSON array ---

if [ ${#DETECTED[@]} -eq 0 ]; then
  echo "[]"
else
  printf '['
  for i in "${!DETECTED[@]}"; do
    [ "$i" -gt 0 ] && printf ','
    printf '"%s"' "${DETECTED[$i]}"
  done
  printf ']\n'
fi
