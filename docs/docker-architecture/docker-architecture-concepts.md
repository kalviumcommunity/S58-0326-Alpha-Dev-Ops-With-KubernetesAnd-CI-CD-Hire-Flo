# Docker Architecture: Images, Containers, and Layers
## HireFlow | Team 02 | Sprint #3 | Assignment 4.13

---

## Docker is a Platform, Not Just a Tool

Most beginners think Docker = `docker run`. 
In reality, Docker is a platform made of multiple components:
```
┌─────────────────────────────────────────────────────────────┐
│                    DOCKER PLATFORM                          │
│                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │  Docker CLI  │    │  Docker API  │    │  Docker Hub  │  │
│  │  (docker     │───>│  (REST API)  │    │  / GHCR      │  │
│  │   commands)  │    │              │    │  (Registry)  │  │
│  └──────────────┘    └──────┬───────┘    └──────────────┘  │
│                             │                               │
│                             ▼                               │
│                    ┌──────────────────┐                     │
│                    │   Docker Daemon  │                     │
│                    │   (dockerd)      │                     │
│                    │                 │                     │
│                    │  Manages:        │                     │
│                    │  - Images        │                     │
│                    │  - Containers    │                     │
│                    │  - Networks      │                     │
│                    │  - Volumes       │                     │
│                    └──────────────────┘                     │
│                             │                               │
│                             ▼                               │
│                    ┌──────────────────┐                     │
│                    │  Container       │                     │
│                    │  Runtime         │                     │
│                    │  (containerd)    │                     │
│                    └──────────────────┘                     │
│                                                             │
│                    Host Operating System (Linux)            │
└─────────────────────────────────────────────────────────────┘
```

### Components Explained

**Docker CLI** — what you type (`docker build`, `docker run`, `docker push`)

**Docker Daemon (dockerd)** — the background service that does the
actual work. When you type `docker build`, the CLI sends the request
to the daemon which builds the image.

**Container Runtime (containerd)** — the low-level component that
actually starts and stops containers using Linux kernel features
(namespaces + cgroups). Kubernetes also uses containerd directly.

**Registry (GHCR for HireFlow)** — remote storage for images.
The daemon pushes images to and pulls images from the registry.

---

## Docker Images — The Immutable Blueprint

A Docker image is a **read-only, immutable blueprint** for a container.
```
ANALOGY:
  Image  = Recipe (instructions + ingredients list)
  Container = The cooked dish (running instance)

  You can cook the same dish (run the same image) many times.
  The recipe (image) never changes.
  Each dish (container) is independent.
```

### What an Image Contains
```
┌─────────────────────────────────────────────┐
│              DOCKER IMAGE                   │
│         ghcr.io/team02/hireflow             │
│                                             │
│  ┌─────────────────────────────────────┐    │
│  │  APPLICATION LAYER                  │    │
│  │  → HireFlow source code             │    │
│  │  → Form schema v2.4.1               │    │
│  │  → Static assets                    │    │
│  ├─────────────────────────────────────┤    │
│  │  DEPENDENCY LAYER                   │    │
│  │  → node_modules/                    │    │
│  │  → npm packages (express, etc.)     │    │
│  ├─────────────────────────────────────┤    │
│  │  RUNTIME LAYER                      │    │
│  │  → Node.js 18.x binary              │    │
│  │  → npm                              │    │
│  ├─────────────────────────────────────┤    │
│  │  BASE LAYER                         │    │
│  │  → node:18-alpine                   │    │
│  │  → Alpine Linux (minimal OS)        │    │
│  └─────────────────────────────────────┘    │
│                                             │
│  READ-ONLY: Cannot be modified after build  │
└─────────────────────────────────────────────┘
```

### Immutability Rule
```
Commit A → Build → Image tag: sha-a3f91b2  ← FROZEN FOREVER
Commit B → Build → Image tag: sha-7e2d45f  ← FROZEN FOREVER

sha-a3f91b2 will ALWAYS contain form v2.4.1
It cannot be accidentally changed.
This is what makes deployments predictable.
```

---

## Docker Layers — How Images Are Actually Built

This is the most important architectural concept in Docker.

**An image is NOT one big file. It is a stack of layers.**

Each instruction in a Dockerfile creates one layer:
```
Dockerfile Instruction          Layer Created
──────────────────────          ─────────────────────────────────
FROM node:18-alpine        →    Layer 1: Base OS + Node.js runtime
                                (~50MB, pulled from Docker Hub)

WORKDIR /app               →    Layer 2: Directory created in filesystem
                                (~0MB, just metadata)

COPY package*.json ./      →    Layer 3: package.json added
                                (~1KB)

RUN npm install            →    Layer 4: node_modules installed
                                (~80MB, all npm packages)

COPY . .                   →    Layer 5: Application source code copied
                                (~2MB)

CMD ["node", "server.js"]  →    Layer 6: Metadata only (no filesystem change)
                                (~0MB)
```

### Visual Layer Stack
```
┌─────────────────────────────────────────┐
│  Layer 6: CMD ["node", "server.js"]     │ ← Metadata
├─────────────────────────────────────────┤
│  Layer 5: COPY . .                      │ ← App source code (~2MB)
├─────────────────────────────────────────┤
│  Layer 4: RUN npm install               │ ← node_modules (~80MB)
├─────────────────────────────────────────┤
│  Layer 3: COPY package*.json ./         │ ← package.json (~1KB)
├─────────────────────────────────────────┤
│  Layer 2: WORKDIR /app                  │ ← Directory metadata
├─────────────────────────────────────────┤
│  Layer 1: FROM node:18-alpine           │ ← Base OS + Node.js (~50MB)
└─────────────────────────────────────────┘
         READ-ONLY STACK
         Total image size: ~132MB
```

---

## Layer Caching — Why Order Matters

Docker caches each layer. If a layer hasn't changed, Docker reuses
the cached version instead of rebuilding it.

**Cache invalidation rule:** If any layer changes, ALL layers
ABOVE it are rebuilt from scratch.

### Bad Layer Order (Slow Builds)
```
FROM node:18-alpine
COPY . .                ← copies ALL source code first
RUN npm install         ← runs AFTER source copy

Problem: Every time ANY source file changes (even README.md),
Docker invalidates this layer and re-runs npm install.
npm install takes 2-3 minutes. This happens on EVERY build.
```

### Good Layer Order (Fast Builds)
```
FROM node:18-alpine
COPY package*.json ./   ← copy ONLY package files first
RUN npm install         ← runs only when package.json changes
COPY . .                ← copy source code LAST

Benefit: npm install only re-runs when package.json changes.
Source code changes (which happen constantly) only rebuild
the cheap COPY layer — seconds, not minutes.
```

### Cache Behavior Visualization
```
SCENARIO: Developer changes server.js (source code only)

BAD ORDER:                          GOOD ORDER:
──────────────────────              ──────────────────────
FROM node:18-alpine ✓ cached        FROM node:18-alpine ✓ cached
COPY . .            ✗ CHANGED       COPY package*.json  ✓ cached
RUN npm install     ✗ REBUILD       RUN npm install     ✓ cached
                    (~3 min)        COPY . .            ✗ CHANGED
                                                        (~2 sec)

Result: 3 minutes per build         Result: 2 seconds per build
```

### Why This Matters for HireFlow

During campus hiring season, developers push many small fixes.
With bad layer order: every fix triggers a 3-minute npm install.
With good layer order: rebuilds take seconds.
This directly impacts CI pipeline speed and developer productivity.

---

## Containers — Running Instances of Images

A container is a running instance of an image with one addition:
a thin **writable layer** on top.
```
┌─────────────────────────────────────────────┐
│              RUNNING CONTAINER              │
│                                             │
│  ┌─────────────────────────────────────┐    │
│  │  WRITABLE LAYER (container layer)   │    │ ← Temporary!
│  │  → Runtime logs                     │    │   Discarded on stop
│  │  → Temp files created by app        │    │
│  │  → Any runtime changes              │    │
│  └─────────────────────────────────────┘    │
│                    │                        │
│                    │ sits on top of         │
│                    ▼                        │
│  ┌─────────────────────────────────────┐    │
│  │  IMAGE LAYERS (read-only)           │    │
│  │  Layer 5: App source code           │    │
│  │  Layer 4: node_modules              │    │
│  │  Layer 3: package.json              │    │
│  │  Layer 2: WORKDIR                   │    │
│  │  Layer 1: node:18-alpine            │    │
│  └─────────────────────────────────────┘    │
└─────────────────────────────────────────────┘
```

### Critical Container Behavior Rules

**Rule 1: Image layers are shared between containers**
```
Pod 1 (container)  ┐
Pod 2 (container)  ├── All share the SAME read-only image layers
Pod 3 (container)  ┘   Each has its OWN writable layer on top

Memory benefit: 3 pods don't need 3 copies of node_modules.
They share one read-only copy.
```

**Rule 2: Writable layer is temporary**
```
Container starts  → writable layer created
App writes logs   → logs go into writable layer
Container stops   → writable layer DESTROYED

This means: Any data written inside a container is LOST
when the container stops (unless using Volumes).

For HireFlow: Application logs must go to a logging
service (Loki/Fluent Bit), NOT written inside the container.
```

**Rule 3: Modifying a running container does NOT change the image**
```
Wrong workflow:
  docker exec container npm install new-package  ← modifies writable layer only
  Container stops → change LOST
  New pod starts  → change GONE

Correct workflow:
  Update package.json → Rebuild image → Deploy new image
  Change is now in the image → persists forever
```

---

## Image vs Container — Side-by-Side Comparison

| Aspect | Docker Image | Docker Container |
|--------|-------------|-----------------|
| State | Static, immutable | Dynamic, running |
| Layers | Read-only stack | Read-only + writable top layer |
| Storage | Registry (GHCR) | Running on host |
| Lifecycle | Built once, reused many times | Created, runs, stops, deleted |
| Changes | New build needed | Writable layer (temporary) |
| Analogy | Recipe / Blueprint | Cooked dish / Running instance |
| Count | One image | Many containers from same image |

---

## Docker Lifecycle — Full Picture
```
Dockerfile
    │
    │ docker build
    ▼
Docker Image (read-only layers)
    │
    │ docker push
    ▼
Registry (GHCR)
    │
    │ docker pull / kubectl applies deployment
    ▼
Docker Image (on host)
    │
    │ docker run / Kubernetes creates pod
    ▼
Running Container
    │
    ├── Process executes (Node.js server)
    ├── Writable layer accumulates runtime data
    ├── Health checks run
    │
    │ Container stops (crash / scale down)
    ▼
Stopped Container
    │
    │ Writable layer discarded
    │ Image layers remain intact on host
    │
    │ docker run again (or K8s restarts pod)
    ▼
New Running Container (fresh writable layer)
```

---

## How This Applies to HireFlow Kubernetes Pods
```
KUBERNETES POD = Docker Container (managed by K8s)

HireFlow Deployment with 3 replicas:

Registry (GHCR)
ghcr.io/team02/hireflow:sha-a3f91b2
        │
        │ pulled once, cached on node
        ▼
Node 1 (Kubernetes Worker)
┌────────────────────────────────────────┐
│  Shared image layers (read-only)       │
│  node:18-alpine + Node.js + node_mods  │
│                                        │
│  Pod 1  ┌──────────────────┐           │
│         │ Writable layer   │           │
│         │ (logs, temp)     │           │
│         └──────────────────┘           │
│                                        │
│  Pod 2  ┌──────────────────┐           │
│         │ Writable layer   │           │
│         │ (logs, temp)     │           │
│         └──────────────────┘           │
└────────────────────────────────────────┘

Memory saved: node_modules loaded ONCE, shared by both pods.
```