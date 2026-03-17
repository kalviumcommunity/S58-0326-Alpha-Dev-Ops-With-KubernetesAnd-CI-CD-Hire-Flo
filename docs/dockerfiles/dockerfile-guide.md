# Dockerfile Guide — HireFlow Team 02
## Sprint #3 | Assignment 4.14

---

## Overview

HireFlow has two Dockerfiles:

| File | Base Image | Strategy | Final Size |
|------|-----------|----------|------------|
| `backend/Dockerfile` | node:18-alpine | Single-stage | ~132MB |
| `frontend/Dockerfile` | node:18-alpine + nginx:alpine | Multi-stage | ~25MB |

---

## Backend Dockerfile — Layer Analysis
```
Layer   Instruction              Size      Cache Behavior
──────  ───────────────────────  ────────  ──────────────────────────────
1       FROM node:18-alpine      ~50MB     Cached unless base tag changes
2       WORKDIR /app             ~0MB      Always cached
3       COPY package*.json ./    ~1KB      Cached unless deps change
4       RUN npm install          ~80MB     Cached unless package.json changes
5       COPY . .                 ~2MB      Rebuilds on EVERY source change
6       EXPOSE 3000              ~0MB      Always cached
7       HEALTHCHECK              ~0MB      Always cached
8       CMD ["node","server.js"] ~0MB      Always cached
```

### Why This Order Saves CI Time
```
Developer fixes a bug in server.js:

Layers 1-4: CACHE HIT  (0 seconds — ~131MB served from cache)
Layer 5:    REBUILD     (~2 seconds — copies new source)
Layers 6-8: REBUILD     (~0 seconds — metadata only)

Total rebuild time: ~2 seconds
Without this optimization: ~3 minutes (npm install re-runs)
```

---

## Frontend Dockerfile — Multi-Stage Explained
```
STAGE 1 (builder)           STAGE 2 (runner)
────────────────────        ────────────────────
node:18-alpine              nginx:alpine
node_modules/ (~80MB)       ← NOT included
React source (~2MB)         ← NOT included
npm, node binaries          ← NOT included
                            Built files only (~3MB)
                            Nginx binary (~20MB)

Final image: ~25MB (vs ~180MB without multi-stage)
```

### Why Multi-Stage for Frontend?

Production containers should contain ONLY what is needed to run.
Node.js, npm, and node_modules are build tools — not runtime tools.
After `npm run build`, the HTML/CSS/JS files are all that's needed.
Nginx serves those static files efficiently at ~25MB total.

---

## Base Image Choice: Why Alpine?

| Base Image | Size | Use Case |
|-----------|------|----------|
| node:18 | ~900MB | Full Debian — avoid for production |
| node:18-slim | ~200MB | Reduced Debian — acceptable |
| node:18-alpine | ~50MB | Alpine Linux — recommended ✓ |
| node:18-distroless | ~30MB | Google distroless — advanced |

Alpine chosen for HireFlow because:
- Official Node.js image with Alpine Linux base
- ~50MB vs ~900MB for full Debian node image
- Includes package manager (apk) if additional tools needed
- Battle-tested in production environments
- `wget` available for HEALTHCHECK command

---

## .dockerignore — Why It Matters

Without .dockerignore:
```
docker build context: ~200MB (includes node_modules)
Build time: slow (large context upload to daemon)
```

With .dockerignore:
```
docker build context: ~3MB (only source code)
Build time: fast
node_modules never sent to daemon (npm install creates fresh ones)
```

Most important exclusions:
- `node_modules/` — must be installed fresh inside container
- `.env` files — secrets must NEVER be baked into images
- `.git/` — version control data not needed in production

---

## How to Build and Test Locally
```bash
# Build backend image
cd backend
docker build -t hireflow-backend:local .

# Run backend container
docker run -p 3000:3000 \
  -e FORM_VERSION=v2.4.1 \
  -e NODE_ENV=production \
  hireflow-backend:local

# Test it
curl http://localhost:3000/health
curl http://localhost:3000/api/form-version

# Check image size
docker images hireflow-backend:local

# View layers
docker history hireflow-backend:local
```

---

## HEALTHCHECK Explanation

Both Dockerfiles include a HEALTHCHECK instruction:
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:3000/health || exit 1
```

| Parameter | Value | Meaning |
|-----------|-------|---------|
| interval | 30s | Check every 30 seconds |
| timeout | 3s | Fail if no response in 3 seconds |
| retries | 3 | Mark unhealthy after 3 failures |

This mirrors the Kubernetes liveness probe behavior. If the health
endpoint stops responding, Docker/Kubernetes marks the container
unhealthy and restarts it automatically.