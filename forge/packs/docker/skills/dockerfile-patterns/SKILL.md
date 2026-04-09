---
name: docker:dockerfile-patterns
description: Dockerfile patterns — multi-stage builds, non-root user, layer caching, .dockerignore
trigger: |
  - Creating or modifying a Dockerfile
  - Docker image is too large
  - Build is slow (cache misses)
  - Security review of container setup
  - docker-compose.yml for local development
skip_when: |
  - Dockerfile already follows multi-stage, non-root, and .dockerignore patterns
---

# Dockerfile Patterns

## Multi-Stage Builds

Separate build-time dependencies from the runtime image. Final image contains only what's needed to run.

```dockerfile
# Stage 1: Build
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --frozen-lockfile
COPY . .
RUN npm run build

# Stage 2: Production (no dev deps, no source)
FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

# Copy only production artifacts
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

EXPOSE 3000
CMD ["node", "dist/server.js"]
```

## Non-Root User

Never run processes as root inside a container.

```dockerfile
FROM node:22-alpine AS runner
WORKDIR /app

# Create a non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

COPY --from=builder --chown=nextjs:nodejs /app/dist ./dist
COPY --from=builder --chown=nextjs:nodejs /app/node_modules ./node_modules

USER nextjs  # switch before CMD
EXPOSE 3000
CMD ["node", "dist/server.js"]
```

## Layer Caching

Order layers from least-to-most frequently changed. `package.json` changes less often than source code.

```dockerfile
# BAD — source change invalidates npm install cache
COPY . .
RUN npm ci

# GOOD — deps cached separately from source
COPY package*.json ./
RUN npm ci --frozen-lockfile   # cached unless package*.json changes
COPY . .                       # invalidates only subsequent layers
RUN npm run build
```

**Cache rules**:
- System packages first (`apt-get`, `apk add`)
- Dependency manifests second (`package.json`, `go.mod`, `requirements.txt`)
- Application source last
- Each `RUN` statement is a layer — chain related commands with `&&`

## .dockerignore

Always create `.dockerignore` to exclude dev files from the build context.

```
# .dockerignore
node_modules
.git
.env*
*.log
dist
coverage
.next
*.test.ts
*.spec.ts
docs
README.md
```

## Docker Compose for Local Development

```yaml
# docker-compose.yml
services:
  app:
    build:
      context: .
      target: builder  # dev stage with hot-reload
    ports:
      - "3000:3000"
    volumes:
      - .:/app             # mount source for hot-reload
      - /app/node_modules  # don't override container's node_modules
    environment:
      - NODE_ENV=development
    env_file:
      - .env.local

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: myapp
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

volumes:
  postgres_data:
```

## Image Size Checklist

```bash
# Inspect layer sizes
docker image history my-app:latest

# Scan for vulnerabilities
docker scout cves my-app:latest
```

## Checklist

- [ ] Multi-stage build — final image from minimal base (`alpine`, `distroless`)
- [ ] Non-root user created and switched to before `CMD`
- [ ] `.dockerignore` excludes `node_modules`, `.git`, `.env*`, test files
- [ ] Dependency files copied before source (cache optimization)
- [ ] Related `RUN` commands chained with `&&` and `\` line continuation
- [ ] No secrets in `ENV` or `ARG` — use runtime secrets or `.env_file`
- [ ] Ports documented with `EXPOSE`
- [ ] `CMD` uses exec form (`["node", "server.js"]`), not shell form
