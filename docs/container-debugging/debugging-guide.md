# Container Debugging Guide — HireFlow
## Team 02 | Sprint #3 | Assignment 4.15

---

## The Local Container Debug WorkflowWrite/Update Dockerfile
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

---

## Essential Commands Reference

### Build Commands
```bashBasic build
docker build -t hireflow-backend:local .Build with no cache (force full rebuild)
docker build --no-cache -t hireflow-backend:local .Build and see verbose output
docker build --progress=plain -t hireflow-backend:local .

### Run Commands
```bashRun in background (detached mode)
docker run -d --name hireflow-test -p 3000:3000 hireflow-backend:localRun in foreground (see logs immediately)
docker run --rm --name hireflow-test -p 3000:3000 hireflow-backend:localRun with environment variables
docker run -d 
--name hireflow-test 
-p 3000:3000 
-e FORM_VERSION=v2.4.1 
-e NODE_ENV=production 
hireflow-backend:localRun and override startup command (debugging)
docker run -it --rm hireflow-backend:local sh

### Inspect Commands
```bashList running containers
docker psList all containers (including stopped)
docker ps -aView container logs
docker logs hireflow-testFollow logs in real time
docker logs -f hireflow-testShow last 50 lines of logs
docker logs --tail 50 hireflow-testFull container metadata
docker inspect hireflow-testCheck environment variables
docker exec hireflow-test envCheck running processes
docker exec hireflow-test ps auxCheck image layers
docker history hireflow-backend:localCheck image size
docker images hireflow-backend:local

### Interactive Debug Commands
```bashOpen shell inside running container
docker exec -it hireflow-test shCheck filesystem
docker exec hireflow-test ls -la /appCheck a specific file
docker exec hireflow-test cat /app/server.jsCheck Node.js version
docker exec hireflow-test node --versionCheck if port is listening inside container
docker exec hireflow-test netstat -tlnp 2>/dev/null || 
docker exec hireflow-test ss -tlnp

### Cleanup Commands
```bashStop a container
docker stop hireflow-testRemove a container
docker rm hireflow-testStop and remove in one command
docker rm -f hireflow-testRemove the image
docker rmi hireflow-backend:localRemove ALL unused images, containers, networks
docker system prune -f

---

## Common Container Issues and Fixes

### Issue 1: Port not accessible from hostSymptom:  curl http://localhost:3000/health → Connection refused
BUT container shows as running in docker psDiagnosis:
docker ps --filter name=hireflow-test
Check PORTS column — if empty, port not mappedRoot cause: -p flag missing from docker run commandFix:
docker rm -f hireflow-test
docker run -d --name hireflow-test -p 3000:3000 hireflow-backend:localValidation:
curl http://localhost:3000/health → 200 OK ✅

### Issue 2: Container exits immediately after startingSymptom:  docker run → container starts then stops instantly
docker ps → container not listedDiagnosis:
docker ps -a  → shows container in "Exited" state
docker logs hireflow-test  → shows error messageCommon causes:

Application crash on startup (check logs for error)
Missing required environment variable
Wrong CMD in Dockerfile (command not found)
Missing file that server.js tries to require
Fix example (missing env var):
docker run -d 
--name hireflow-test 
-p 3000:3000 
-e FORM_VERSION=v2.4.1 \   ← add missing variable
hireflow-backend:local

### Issue 3: Environment variable not injectedSymptom:  App shows default value instead of expected value
e.g., FORM_VERSION shows "v1.0.0" not "v2.4.1"Diagnosis:
docker exec hireflow-test env | grep FORM_VERSION
Shows: FORM_VERSION=v1.0.0 (wrong value or missing)Fix:
docker rm -f hireflow-test
docker run -d 
--name hireflow-test 
-p 3000:3000 
-e FORM_VERSION=v2.4.1 \  ← correct value
hireflow-backend:localValidation:
curl http://localhost:3000/api/form-version
Returns: {"formVersion":"v2.4.1"} ✅

### Issue 4: node_modules missing inside containerSymptom:  Container exits with "Cannot find module 'express'"Diagnosis:
docker exec hireflow-test ls /app/node_modules
Error: no such file or directoryRoot cause: .dockerignore excludes node_modules (correct)
BUT npm install step missing or failed in DockerfileFix: Check Dockerfile has RUN npm install before COPY . .
Rebuild: docker build --no-cache -t hireflow-backend:local .

### Issue 5: Old code running after source changeSymptom:  Changed server.js but container still runs old codeRoot cause: Running old image — not rebuilt after code changeFix:
Rebuild image first
docker build -t hireflow-backend:local .Then rerun container from new image
docker rm -f hireflow-test
docker run -d --name hireflow-test -p 3000:3000 hireflow-backend:local

---

## Debugging Decision TreeContainer not working
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