# Artifact Flow Documentation — HireFlow Team 02

This folder documents the CI/CD artifact flow for the HireFlow
recruitment platform (Sprint #3, Assignment 4.3).

## Files

| File | Contents |
|------|---------|
| `artifact-flow-concepts.md` | Full stage-by-stage explanation with ASCII diagrams |
| `hireflow-artifact-flow-diagram.md` | Complete end-to-end flow and rollback diagram |
| `rollback-and-traceability.md` | Rollback scenarios and traceability chain |

## The Flow
```
Source (Git Commit)
      ↓
CI Pipeline (GitHub Actions)
      ↓
Docker Image (Immutable artifact)
      ↓
Registry (GHCR — versioned storage)
      ↓
Kubernetes Cluster (Running containers)
```

## Why This Matters for HireFlow

- Surge scaling: K8s pulls pre-built image, scales pods in 5 seconds
- Form version tracing: image tag → git commit → form schema version
- Safe rollback: `kubectl rollout undo` restores stable image instantly