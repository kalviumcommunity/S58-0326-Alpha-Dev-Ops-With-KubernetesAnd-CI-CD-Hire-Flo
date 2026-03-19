# CI/CD Execution Model & Responsibility Boundaries
## HireFlow | Team 02 | Sprint #3 | Assignment 4.5

---

## The Full Execution Model
```
CODE CHANGE (Developer)
        │
        │ git push / Pull Request
        ▼
┌─────────────────────────────────────────────────────────┐
│              CONTINUOUS INTEGRATION (CI)                │
│         "Is this code safe to merge?"                   │
│                                                         │
│  Job 1: ci-validate                                     │
│    → checkout code                                      │
│    → npm install                                        │
│    → npm test          ← GATE: fails = pipeline stops   │
│    → lint check        ← GATE: fails = pipeline stops   │
│                                                         │
│  Job 2: ci-build-push (only on main push)              │
│    → docker build      ← creates immutable artifact     │
│    → tag: sha-a3f91b2  ← git SHA for traceability       │
│    → tag: v2.4.1       ← form version for recruiters    │
│    → docker push       ← stores in Docker Hub           │
└───────────────────────────┬─────────────────────────────┘
                            │
                            │ artifact ready in registry
                            ▼
┌─────────────────────────────────────────────────────────┐
│              CONTINUOUS DEPLOYMENT (CD)                 │
│         "How do we safely run this version?"            │
│                                                         │
│  Job: cd-deploy (runs after ci-build-push)              │
│    → verify artifact exists in registry                 │
│    → update k8s/deployment.yaml with new image tag      │
│    → kubectl apply manifests to cluster                 │
│    → monitor rollout status                             │
│                                                         │
│  CD NEVER rebuilds code.                                │
│  CD ONLY deploys the artifact CI produced.              │
└───────────────────────────┬─────────────────────────────┘
                            │
                            │ desired state sent to K8s
                            ▼
┌─────────────────────────────────────────────────────────┐
│              KUBERNETES INFRASTRUCTURE                  │
│         "Run and maintain the desired state"            │
│                                                         │
│  → Scheduler places pods on nodes                       │
│  → kubelet pulls image from Docker Hub                  │
│  → containerd starts containers                         │
│  → Readiness probe validates pod is healthy             │
│  → Service routes traffic to healthy pods               │
│  → Rolling update: new pods up before old pods down     │
│  → ReplicaSet self-heals crashed pods                   │
│  → HPA scales during campus hiring surges               │
│                                                         │
│  These happen OUTSIDE the pipeline entirely.            │
│  Pipeline triggers K8s — K8s executes independently.   │
└─────────────────────────────────────────────────────────┘
```

---

## Responsibility Table

| Action | Owner | Stage |
|--------|-------|-------|
| Writing business logic | Developer | Application code |
| Writing unit tests | Developer | Application code |
| Installing dependencies | CI pipeline | CI |
| Running tests | CI pipeline | CI |
| Building Docker image | CI pipeline | CI |
| Tagging image with SHA | CI pipeline | CI |
| Pushing image to registry | CI pipeline | CI |
| Updating k8s manifests | CD pipeline | CD |
| Applying manifests to cluster | CD pipeline | CD |
| Monitoring rollout | CD pipeline | CD |
| Scheduling pods on nodes | Kubernetes | Infrastructure |
| Pulling image from registry | Kubernetes (kubelet) | Infrastructure |
| Starting containers | Kubernetes (containerd) | Infrastructure |
| Running health probes | Kubernetes (kubelet) | Infrastructure |
| Routing traffic | Kubernetes (kube-proxy) | Infrastructure |
| Restarting crashed pods | Kubernetes (ReplicaSet) | Infrastructure |
| Scaling during surges | Kubernetes (HPA) | Infrastructure |

---

## CI vs CD — Core Distinction
```
CONTINUOUS INTEGRATION          CONTINUOUS DEPLOYMENT
──────────────────────────      ──────────────────────────────
Triggered by: PR or push        Triggered by: CI success
Validates: code quality         Validates: deployment health
Produces: Docker image          Consumes: Docker image from CI
Answers: "Safe to merge?"       Answers: "Safe to run?"
Runs on: every branch push      Runs on: main branch only
Fails: stops the merge          Fails: triggers rollback
Duration: 2-5 minutes           Duration: 1-3 minutes
```

---

## Why Responsibility Separation Matters

### For HireFlow Specifically
```
SCENARIO 1: Developer pushes buggy code

WITHOUT separation:
  Code pushed → immediately deployed → platform broken
  8000 candidates get errors during hiring surge

WITH separation:
  Code pushed → CI runs tests → tests fail
  Pipeline stops → NO image built → NO deployment
  Recruiter platform never affected

SCENARIO 2: Bad deployment image

WITHOUT separation:
  No way to rollback easily — code and deploy entangled

WITH separation:
  kubectl rollout undo deployment/hireflow
  Kubernetes reverts to previous image from registry
  CD re-runs with previous tag
  Platform restored in ~60 seconds

SCENARIO 3: Pod crashes during surge

WITHOUT separation:
  Someone has to manually restart the server

WITH separation:
  Kubernetes (infrastructure) handles this independently
  ReplicaSet recreates pod in ~10 seconds
  Pipeline is not involved — K8s self-heals
```

---

## Safe Pipeline Modifications

### Impact of Changes to Each Stage
```
CHANGE TYPE                  IMPACT              RISK LEVEL
─────────────────────────    ──────────────────  ──────────
Modify test steps (CI)       CI validation       Low-Medium
  → May miss bugs if         changes
    tests weakened

Modify build steps (CI)      Artifact changes    Medium
  → Wrong base image
    or Dockerfile affects
    all future deployments

Modify deploy steps (CD)     LIVE SYSTEMS        High ⚠️
  → Wrong kubectl command
    can break production

Modify K8s manifests         LIVE SYSTEMS        High ⚠️
  → Wrong replica count,
    broken probes, wrong
    resource limits

RULE: Pipeline changes must be reviewed like production code.
```

### What Requires Careful Review
```
HIGH RISK — Review carefully:
  - Changes to cd-deploy job
  - Changes to k8s/*.yaml manifests
  - Changes to image tag strategy
  - Adding/removing pipeline stages

MEDIUM RISK — Review normally:
  - Changes to ci-validate job
  - Changes to test commands
  - Changes to build arguments

LOW RISK — Quick review:
  - Adding comments to pipeline
  - Updating documentation
  - Changing notification messages
```

---

## Common Misconceptions — Corrected

| Misconception | Correct Understanding |
|--------------|----------------------|
| "CI deploys code" | CI only builds and validates — CD deploys |
| "CD recompiles the application" | CD uses pre-built image from CI registry |
| "Pipelines replace Kubernetes" | Pipelines trigger K8s — K8s runs workloads |
| "Pipeline failure = site is down" | Existing deployment keeps running — only new deployments blocked |
| "Rollback means redeploy from code" | Rollback uses existing image in registry — no rebuild |