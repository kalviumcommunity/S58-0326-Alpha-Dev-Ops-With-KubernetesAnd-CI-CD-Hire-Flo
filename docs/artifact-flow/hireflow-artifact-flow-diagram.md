# HireFlow Artifact Flow Diagram
## Team 02 | Sprint #3 | Assignment 4.3

---

## Complete End-to-End Flow
```
╔══════════════════════════════════════════════════════════════╗
║           HIREFLOW CI/CD ARTIFACT FLOW                       ║
║           Team 02 | Sprint #3                                ║
╚══════════════════════════════════════════════════════════════╝

  DEVELOPER
  ─────────
  feat(form): add github profile field
  git push origin main
          │
          │ webhook trigger
          ▼
  ┌───────────────────┐
  │   GITHUB REPO     │
  │   Commit:         │
  │   sha-a3f91b2     │
  └────────┬──────────┘
           │ on: push to main
           ▼
  ┌───────────────────────────────────────────────┐
  │              GITHUB ACTIONS CI                │
  │                                               │
  │  Job 1: build-and-test                        │
  │  ┌─────────────────────────────────────────┐  │
  │  │ 1. actions/checkout@v3                  │  │
  │  │ 2. setup-node@v3 (Node.js 18)           │  │
  │  │ 3. npm install                          │  │
  │  │ 4. npm test          ← GATE: must pass  │  │
  │  └─────────────────────────────────────────┘  │
  │                  │ if tests pass              │
  │  Job 2: docker-build                          │
  │  ┌─────────────────────────────────────────┐  │
  │  │ 5. docker build -t hireflow .            │  │
  │  │ 6. docker tag hireflow:sha-a3f91b2      │  │
  │  │ 7. docker push → GHCR                   │  │
  │  └─────────────────────────────────────────┘  │
  └───────────────────────────────────────────────┘
           │ image pushed
           ▼
  ┌───────────────────────────────────────────────┐
  │         GITHUB CONTAINER REGISTRY (GHCR)      │
  │         ghcr.io/team02/hireflow               │
  │                                               │
  │  ┌─────────────────────────────────────────┐  │
  │  │ sha-a3f91b2  │ form v2.4.1 │ today      │  │
  │  │ sha-7e2d45f  │ form v2.3.0 │ 2 days ago │  │
  │  │ sha-1c8a90b  │ form v2.2.5 │ 1 week ago │  │
  │  └─────────────────────────────────────────┘  │
  │  Full version history — rollback anytime       │
  └───────────────────────────────────────────────┘
           │ kubectl apply / CD pipeline
           ▼
  ┌───────────────────────────────────────────────┐
  │           KUBERNETES CLUSTER                  │
  │                                               │
  │  Deployment: hireflow                         │
  │  image: ghcr.io/team02/hireflow:sha-a3f91b2   │
  │  replicas: 3 → 7 (HPA during surge)           │
  │                                               │
  │  ┌─────────┐  ┌─────────┐  ┌─────────┐       │
  │  │  Pod 1  │  │  Pod 2  │  │  Pod 3  │  ...  │
  │  │ RUNNING │  │ RUNNING │  │ RUNNING │       │
  │  └─────────┘  └─────────┘  └─────────┘       │
  │                                               │
  │  Service → LoadBalancer → Candidates          │
  └───────────────────────────────────────────────┘
           │
           ▼
  CANDIDATE submits application
  Form version v2.4.1 stamped on submission
  Recruiter dashboard shows exact form version
```

---

## Rollback Flow
```
PROBLEM DETECTED: form v2.4.1 has a bug
        │
        ▼
kubectl rollout undo deployment/hireflow
        │
        ▼
Kubernetes checks deployment history
        │
        ▼
Previous image: ghcr.io/team02/hireflow:sha-7e2d45f
        │
        ▼
Rolling update (pod by pod):
  Pod 1: sha-a3f91b2 → sha-7e2d45f ✓
  Pod 2: sha-a3f91b2 → sha-7e2d45f ✓
  Pod 3: sha-a3f91b2 → sha-7e2d45f ✓
        │
        ▼
Platform restored to form v2.3.0 in ~60 seconds
Zero data loss. Zero rebuild required.
```

---

## Stage Summary Table

| Stage | Tool Used | Input | Output | Key Benefit |
|-------|-----------|-------|--------|-------------|
| Source | GitHub | Developer code | Git commit SHA | Unique change identifier |
| CI Pipeline | GitHub Actions | Commit SHA | Docker image | Validated, tested artifact |
| Docker Image | Docker | Source + deps | Immutable image | Consistent across all environments |
| Registry | GHCR | Docker image | Versioned storage | History, traceability, rollback |
| Cluster | Kubernetes | Image from registry | Running containers | Scalable, reliable deployment |