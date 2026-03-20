# Docker Layer Caching Guide — HireFlow
## Team 02 | Sprint #3 | Assignment 4.13

---

## Why Caching Matters

Every second saved in the CI pipeline = faster feedback for developers.
During campus hiring surges, multiple developers push fixes simultaneously.
Slow builds (due to cache invalidation) create a queue of waiting pipelines.

With correct layer ordering:
- Cache hit: build completes in ~10 seconds
- Cache miss: build completes in ~3 minutes

---

## The Caching Rule (Most Important Rule in Docker)

> **When a layer changes, Docker rebuilds that layer AND
> every layer that comes after it.**

Layers BEFORE the change = served from cache ✓
Layers AFTER the change = rebuilt from scratch ✗

---

## HireFlow Layer Strategy

### What Changes Frequently vs Rarely
```
CHANGES RARELY:              CHANGES FREQUENTLY:
────────────────             ───────────────────
Base OS (node:18-alpine)     Application source code
Node.js version              Form schema files
npm package list             Bug fixes
                             Feature additions
```

### Optimal Layer Order for HireFlow
```
# CORRECT ORDER — stable things first, changing things last

FROM node:18-alpine          # RARELY changes → always cached
WORKDIR /app                 # NEVER changes → always cached
COPY package*.json ./        # changes only when deps change
RUN npm install              # expensive → only runs when above changes
COPY . .                     # changes every commit → cheap operation
EXPOSE 3000                  # NEVER changes → always cached
CMD ["node", "server.js"]    # RARELY changes → always cached
```

---

## Cache Scenarios — What Triggers a Rebuild

### Scenario 1: Developer fixes a bug in server.js
```
FROM node:18-alpine    ✓ CACHED  (unchanged)
WORKDIR /app           ✓ CACHED  (unchanged)
COPY package*.json     ✓ CACHED  (package.json unchanged)
RUN npm install        ✓ CACHED  (dependencies unchanged)
COPY . .               ✗ REBUILD (server.js changed)
CMD [...]              ✗ REBUILD (above changed, must follow)

Time: ~5 seconds (only COPY runs, no npm install)
```

### Scenario 2: Developer adds a new npm package
```
FROM node:18-alpine    ✓ CACHED  (unchanged)
WORKDIR /app           ✓ CACHED  (unchanged)
COPY package*.json     ✗ REBUILD (package.json changed)
RUN npm install        ✗ REBUILD (must re-install all packages)
COPY . .               ✗ REBUILD (follows above)
CMD [...]              ✗ REBUILD (follows above)

Time: ~3 minutes (npm install must run)
This is expected and unavoidable when adding packages.
```

### Scenario 3: Team updates Node.js base image version
```
FROM node:18-alpine    ✗ REBUILD (base image updated)
WORKDIR /app           ✗ REBUILD (follows above)
COPY package*.json     ✗ REBUILD (follows above)
RUN npm install        ✗ REBUILD (follows above)
COPY . .               ✗ REBUILD (follows above)
CMD [...]              ✗ REBUILD (follows above)

Time: ~5 minutes (full rebuild)
This is rare and expected.
```

---

## Common Layer Caching Mistakes

### Mistake 1: Copying everything before installing dependencies
```
# WRONG
COPY . .               ← copies everything including source code
RUN npm install        ← cache busted by ANY source file change

# RIGHT  
COPY package*.json ./  ← copy only what npm install needs
RUN npm install        ← cached unless package.json changes
COPY . .               ← source code copied after install
```

### Mistake 2: Running multiple commands that should be combined
```
# WRONG — creates 3 separate layers
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get clean

# RIGHT — one layer, smaller image
RUN apt-get update && \
    apt-get install -y curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

### Mistake 3: Installing tools not needed in production
```
# WRONG — development tools bloat production image
RUN npm install          ← installs devDependencies too

# RIGHT — production only
RUN npm install --omit=dev  ← skips devDependencies
                             ← smaller image, faster pulls
```

---

## Layer Size Impact on HireFlow
```
Layer                          Size      Frequency of Change
─────────────────────────────  ────────  ───────────────────
FROM node:18-alpine            ~50 MB    Rarely
COPY package*.json             ~1 KB     Occasionally
RUN npm install                ~80 MB    Occasionally
COPY . . (source)              ~2 MB     Every commit
─────────────────────────────────────────────────────────────
Total image size:              ~132 MB

With correct caching:
- Most builds only rebuild the ~2 MB source layer
- ~130 MB served from cache
- Build time: seconds, not minutes
```