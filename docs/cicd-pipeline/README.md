# CI/CD Pipeline Documentation — HireFlow Team 02

This folder documents the CI/CD execution model and responsibility
boundaries for the HireFlow recruitment platform
(Sprint #3, Assignment 4.5).

## Files

| File | Contents |
|------|---------|
| `execution-model.md` | Full execution model diagram, responsibility table, CI vs CD distinction, why separation matters, safe pipeline modifications |

## Pipeline File

| File | Location | Purpose |
|------|----------|---------|
| `ci-cd-pipeline.yml` | `.github/workflows/` | Full CI/CD pipeline with annotated responsibility boundaries |

## Pipeline Stages
```
CI Stage               CD Stage              K8s Infrastructure
───────────────────    ──────────────────    ──────────────────
ci-validate        →   cd-deploy         →   Pods scheduled
  - npm install          - update manifest     Containers started
  - npm test             - kubectl apply       Health probes run
  - lint                 - verify rollout      Traffic routed
ci-build-push                                  Self-healing
  - docker build
  - tag image
  - docker push
```

## Key Principle

**CI builds confidence. CD moves artifacts. Kubernetes runs systems.**

Each stage has a single clear responsibility.
No stage crosses into another's territory.