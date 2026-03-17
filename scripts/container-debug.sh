#!/bin/bash

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
docker exec hireflow-test //bin/sh -c "ls -la /app"

echo ""
echo ">> Checking node_modules exists inside container:"
docker exec hireflow-test //bin/sh -c "ls /app/node_modules | head -5"

echo ""
echo ">> Checking Node.js version inside container:"
docker exec hireflow-test node --version

echo ""
echo ">> Checking server.js is present:"
docker exec hireflow-test //bin/sh -c "cat /app/server.js | head -10"

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