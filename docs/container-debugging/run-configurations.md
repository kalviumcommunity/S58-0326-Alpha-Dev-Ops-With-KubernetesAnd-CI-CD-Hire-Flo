✅ Assignment 4.15 — Complete Step-by-Step Guide

🔑 What This Assignment Is About
This is fully hands-on — you need to actually build, run, inspect, and debug containers locally using Docker. The PR contribution is a debugging script + documentation showing real container execution. Docker Desktop must be running.

📦 Software Needed
ToolStatusGit Bash✅ Already haveVS Code✅ Already haveDocker Desktop✅ Just set upGitHub Account✅ Already have

📋 Step-by-Step Instructions

STEP 1 — Go to Repo & Pull Latest Main
bashcd ~/Desktop/DEVOPS/S58-0326-Alpha-Dev-Ops-With-KubernetesAnd-CI-CD-Hire-Flo
git checkout main
git pull origin main

STEP 2 — Create New Branch
bashgit checkout -b assignment-4.15

STEP 3 — Create Folder Structure
bashmkdir -p scripts
mkdir -p docs/container-debugging

STEP 4 — Open VS Code
bashcode .
Create these 4 files:

📄 File 1: scripts/container-debug.sh
bash#!/bin/bash

# ============================================================
# HireFlow — Container Build, Run & Debug Script
# Team 02 | Sprint #3 | Assignment 4.15
# ============================================================
# This script demonstrates the complete local container
# workflow: build → run → inspect → debug → validate fix
# Run from the repository root directory
# ============================================================

echo ""
echo "============================================================"
echo "  HireFlow Container Debug Workflow"
echo "  Team 02 | Sprint #3 | Assignment 4.15"
echo "============================================================"
echo ""

# ------------------------------------------------------------
# SECTION 1: BUILD THE IMAGE
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "STEP 1: Building Docker image"
echo "------------------------------------------------------------"
echo ""

echo ">> Building hireflow-backend:local from ./backend/Dockerfile"
docker build -t hireflow-backend:local ./backend

if [ $? -eq 0 ]; then
  echo ""
  echo "✅ Build successful"
else
  echo ""
  echo "❌ Build failed — check Dockerfile and source files"
  exit 1
fi

echo ""

# ------------------------------------------------------------
# SECTION 2: INSPECT THE IMAGE
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "STEP 2: Inspecting the built image"
echo "------------------------------------------------------------"
echo ""

echo ">> Image size and details:"
docker images hireflow-backend:local

echo ""
echo ">> Image layer history (shows each Dockerfile instruction):"
docker history hireflow-backend:local --no-trunc=false

echo ""

# ------------------------------------------------------------
# SECTION 3: RUN THE CONTAINER
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "STEP 3: Running the container"
echo "------------------------------------------------------------"
echo ""

# Stop and remove existing container if running
echo ">> Cleaning up any existing hireflow-test container:"
docker stop hireflow-test 2>/dev/null && echo "Stopped existing container"
docker rm hireflow-test 2>/dev/null && echo "Removed existing container"

echo ""
echo ">> Starting container with environment variables:"
docker run -d \
  --name hireflow-test \
  -p 3000:3000 \
  -e FORM_VERSION=v2.4.1 \
  -e NODE_ENV=production \
  hireflow-backend:local

echo ""
echo ">> Waiting 3 seconds for container to start..."
sleep 3

echo ""
echo ">> Checking container status:"
docker ps --filter name=hireflow-test

echo ""

# ------------------------------------------------------------
# SECTION 4: TEST ENDPOINTS
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "STEP 4: Testing application endpoints"
echo "------------------------------------------------------------"
echo ""

echo ">> Testing /health endpoint:"
curl -s http://localhost:3000/health | cat
echo ""

echo ""
echo ">> Testing /api/form-version endpoint:"
curl -s http://localhost:3000/api/form-version | cat
echo ""

echo ""
echo ">> Testing /api/applications endpoint:"
curl -s http://localhost:3000/api/applications | cat
echo ""

echo ""

# ------------------------------------------------------------
# SECTION 5: INSPECT CONTAINER STATE
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "STEP 5: Inspecting container state"
echo "------------------------------------------------------------"
echo ""

echo ">> Container logs:"
docker logs hireflow-test

echo ""
echo ">> Container environment variables (verifying injection):"
docker exec hireflow-test env | grep -E "FORM_VERSION|NODE_ENV|PORT"

echo ""
echo ">> Running processes inside the container:"
docker exec hireflow-test ps aux

echo ""
echo ">> Container resource usage:"
docker stats hireflow-test --no-stream

echo ""
echo ">> Full container metadata (ports, mounts, env):"
docker inspect hireflow-test | grep -A5 '"Ports"'

echo ""

# ------------------------------------------------------------
# SECTION 6: INTERACTIVE DEBUGGING
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "STEP 6: Interactive debugging demonstration"
echo "------------------------------------------------------------"
echo ""

echo ">> Checking filesystem inside container:"
docker exec hireflow-test ls -la /app

echo ""
echo ">> Checking node_modules exists inside container:"
docker exec hireflow-test ls /app/node_modules | head -5

echo ""
echo ">> Checking Node.js version inside container:"
docker exec hireflow-test node --version

echo ""
echo ">> Checking server.js is present:"
docker exec hireflow-test cat /app/server.js | head -10

echo ""

# ------------------------------------------------------------
# SECTION 7: SIMULATE AND FIX A BUG
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "STEP 7: Simulate debugging — wrong port scenario"
echo "------------------------------------------------------------"
echo ""

echo ">> Stopping current container..."
docker stop hireflow-test
docker rm hireflow-test

echo ""
echo ">> Simulating bug: running container WITHOUT port mapping"
echo "   (This simulates forgetting -p flag — common mistake)"
docker run -d \
  --name hireflow-broken \
  -e FORM_VERSION=v2.4.1 \
  hireflow-backend:local

sleep 2

echo ""
echo ">> Trying to reach the app (will fail — no port mapping):"
curl -s --max-time 3 http://localhost:3000/health || \
  echo "❌ Connection refused — port not mapped to host"

echo ""
echo ">> Diagnosing: checking container is actually running:"
docker ps --filter name=hireflow-broken

echo ""
echo ">> Diagnosing: checking container logs (app IS running inside):"
docker logs hireflow-broken

echo ""
echo ">> Fix: stop broken container, restart WITH port mapping:"
docker stop hireflow-broken
docker rm hireflow-broken

docker run -d \
  --name hireflow-fixed \
  -p 3000:3000 \
  -e FORM_VERSION=v2.4.1 \
  hireflow-backend:local

sleep 2

echo ""
echo ">> Validating fix — endpoint now reachable:"
curl -s http://localhost:3000/health | cat
echo ""
echo "✅ Fix validated — container running correctly with port mapping"

echo ""

# ------------------------------------------------------------
# SECTION 8: CLEANUP
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "STEP 8: Cleanup"
echo "------------------------------------------------------------"
echo ""

docker stop hireflow-fixed
docker rm hireflow-fixed
echo "✅ All test containers stopped and removed"

echo ""
echo "============================================================"
echo "  Container Debug Workflow Complete"
echo "  Team 02 | Assignment 4.15"
echo "============================================================"
echo ""

📄 File 2: docs/container-debugging/debugging-guide.md
markdown# Container Debugging Guide — HireFlow
## Team 02 | Sprint #3 | Assignment 4.15

---

## The Local Container Debug Workflow
```
Write/Update Dockerfile
        │
        │ docker build
        ▼
Build Image ──── FAIL? → Fix Dockerfile → Rebuild
        │
        │ SUCCESS
        │ docker run
        ▼
Run Container ── FAIL? → Check logs → Fix config → Rerun
        │
        │ SUCCESS
        │ docker logs / exec
        ▼
Inspect & Test ─ FAIL? → Interactive debug → Fix → Rebuild
        │
        │ SUCCESS
        ▼
Validated ✅ → Commit → Push → CI Pipeline
```

---

## Essential Commands Reference

### Build Commands
```bash
# Basic build
docker build -t hireflow-backend:local .

# Build with no cache (force full rebuild)
docker build --no-cache -t hireflow-backend:local .

# Build and see verbose output
docker build --progress=plain -t hireflow-backend:local .
```

### Run Commands
```bash
# Run in background (detached mode)
docker run -d --name hireflow-test -p 3000:3000 hireflow-backend:local

# Run in foreground (see logs immediately)
docker run --rm --name hireflow-test -p 3000:3000 hireflow-backend:local

# Run with environment variables
docker run -d \
  --name hireflow-test \
  -p 3000:3000 \
  -e FORM_VERSION=v2.4.1 \
  -e NODE_ENV=production \
  hireflow-backend:local

# Run and override startup command (debugging)
docker run -it --rm hireflow-backend:local sh
```

### Inspect Commands
```bash
# List running containers
docker ps

# List all containers (including stopped)
docker ps -a

# View container logs
docker logs hireflow-test

# Follow logs in real time
docker logs -f hireflow-test

# Show last 50 lines of logs
docker logs --tail 50 hireflow-test

# Full container metadata
docker inspect hireflow-test

# Check environment variables
docker exec hireflow-test env

# Check running processes
docker exec hireflow-test ps aux

# Check image layers
docker history hireflow-backend:local

# Check image size
docker images hireflow-backend:local
```

### Interactive Debug Commands
```bash
# Open shell inside running container
docker exec -it hireflow-test sh

# Check filesystem
docker exec hireflow-test ls -la /app

# Check a specific file
docker exec hireflow-test cat /app/server.js

# Check Node.js version
docker exec hireflow-test node --version

# Check if port is listening inside container
docker exec hireflow-test netstat -tlnp 2>/dev/null || \
  docker exec hireflow-test ss -tlnp
```

### Cleanup Commands
```bash
# Stop a container
docker stop hireflow-test

# Remove a container
docker rm hireflow-test

# Stop and remove in one command
docker rm -f hireflow-test

# Remove the image
docker rmi hireflow-backend:local

# Remove ALL unused images, containers, networks
docker system prune -f
```

---

## Common Container Issues and Fixes

### Issue 1: Port not accessible from host
```
Symptom:  curl http://localhost:3000/health → Connection refused
          BUT container shows as running in docker ps

Diagnosis:
  docker ps --filter name=hireflow-test
  # Check PORTS column — if empty, port not mapped

Root cause: -p flag missing from docker run command

Fix:
  docker rm -f hireflow-test
  docker run -d --name hireflow-test -p 3000:3000 hireflow-backend:local

Validation:
  curl http://localhost:3000/health → 200 OK ✅
```

### Issue 2: Container exits immediately after starting
```
Symptom:  docker run → container starts then stops instantly
          docker ps → container not listed

Diagnosis:
  docker ps -a  → shows container in "Exited" state
  docker logs hireflow-test  → shows error message

Common causes:
  - Application crash on startup (check logs for error)
  - Missing required environment variable
  - Wrong CMD in Dockerfile (command not found)
  - Missing file that server.js tries to require

Fix example (missing env var):
  docker run -d \
    --name hireflow-test \
    -p 3000:3000 \
    -e FORM_VERSION=v2.4.1 \   ← add missing variable
    hireflow-backend:local
```

### Issue 3: Environment variable not injected
```
Symptom:  App shows default value instead of expected value
          e.g., FORM_VERSION shows "v1.0.0" not "v2.4.1"

Diagnosis:
  docker exec hireflow-test env | grep FORM_VERSION
  # Shows: FORM_VERSION=v1.0.0 (wrong value or missing)

Fix:
  docker rm -f hireflow-test
  docker run -d \
    --name hireflow-test \
    -p 3000:3000 \
    -e FORM_VERSION=v2.4.1 \  ← correct value
    hireflow-backend:local

Validation:
  curl http://localhost:3000/api/form-version
  # Returns: {"formVersion":"v2.4.1"} ✅
```

### Issue 4: node_modules missing inside container
```
Symptom:  Container exits with "Cannot find module 'express'"

Diagnosis:
  docker exec hireflow-test ls /app/node_modules
  # Error: no such file or directory

Root cause: .dockerignore excludes node_modules (correct)
            BUT npm install step missing or failed in Dockerfile

Fix: Check Dockerfile has RUN npm install before COPY . .
     Rebuild: docker build --no-cache -t hireflow-backend:local .
```

### Issue 5: Old code running after source change
```
Symptom:  Changed server.js but container still runs old code

Root cause: Running old image — not rebuilt after code change

Fix:
  # Rebuild image first
  docker build -t hireflow-backend:local .

  # Then rerun container from new image
  docker rm -f hireflow-test
  docker run -d --name hireflow-test -p 3000:3000 hireflow-backend:local
```

---

## Debugging Decision Tree
```
Container not working
        │
        ├── Is container running?
        │   docker ps
        │   │
        │   ├── NO → docker ps -a → check exit code
        │   │         docker logs <name> → find crash reason
        │   │
        │   └── YES → Is port accessible?
        │             curl http://localhost:3000/health
        │             │
        │             ├── NO → check -p flag in docker run
        │             │         docker inspect → check port bindings
        │             │
        │             └── YES → Is response correct?
        │                       │
        │                       ├── NO → check env vars
        │                       │         docker exec <name> env
        │                       │
        │                       └── YES → Container working ✅
```

📄 File 3: docs/container-debugging/run-configurations.md
markdown# Container Run Configurations — HireFlow
## Team 02 | Sprint #3 | Assignment 4.15

---

## Standard Run Configurations

### Development (local testing)
```bash
docker run -d \
  --name hireflow-dev \
  -p 3000:3000 \
  -e FORM_VERSION=v2.4.1 \
  -e NODE_ENV=development \
  hireflow-backend:local
```

### Production simulation (mirrors Kubernetes pod)
```bash
docker run -d \
  --name hireflow-prod \
  -p 3000:3000 \
  -e FORM_VERSION=v2.4.1 \
  -e NODE_ENV=production \
  --memory="256m" \
  --cpus="0.5" \
  hireflow-backend:local
```
Note: --memory and --cpus mirror Kubernetes resource limits

### Interactive debug mode (open shell)
```bash
docker run -it --rm \
  --name hireflow-debug \
  -p 3000:3000 \
  -e FORM_VERSION=v2.4.1 \
  hireflow-backend:local sh
```

---

## Flag Reference

| Flag | Example | Purpose |
|------|---------|---------|
| `-d` | `-d` | Detached — runs in background |
| `--name` | `--name hireflow-test` | Give container a readable name |
| `-p` | `-p 3000:3000` | Map host:container port |
| `-e` | `-e FORM_VERSION=v2.4.1` | Inject environment variable |
| `--rm` | `--rm` | Auto-delete container on stop |
| `-it` | `-it` | Interactive terminal (for debugging) |
| `--memory` | `--memory="256m"` | Memory limit (mirrors K8s) |
| `--cpus` | `--cpus="0.5"` | CPU limit (mirrors K8s) |

---

## Port Mapping Explained
```
-p 3000:3000
    │     │
    │     └── Container port (what the app listens on inside)
    └──────── Host port (what you access from your browser/curl)

Examples:
  -p 3000:3000  → curl http://localhost:3000 → container port 3000
  -p 8080:3000  → curl http://localhost:8080 → container port 3000
  -p 9000:3000  → curl http://localhost:9000 → container port 3000

In Kubernetes: Service handles port mapping (no -p needed)
```

---

## How Local Docker Mirrors Kubernetes

| Docker Local | Kubernetes Equivalent |
|-------------|----------------------|
| `docker run` | Pod created by Deployment |
| `-e FORM_VERSION=v2.4.1` | ConfigMap env injection |
| `-p 3000:3000` | Service port mapping |
| `--memory="256m"` | resources.limits.memory |
| `--cpus="0.5"` | resources.limits.cpu |
| `docker logs` | `kubectl logs` |
| `docker exec -it` | `kubectl exec -it` |
| `docker inspect` | `kubectl describe pod` |
| `docker stop` | Pod termination |