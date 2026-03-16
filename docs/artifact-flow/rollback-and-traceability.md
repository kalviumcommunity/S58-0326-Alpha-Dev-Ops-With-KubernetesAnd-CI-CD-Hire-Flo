# Rollback and Traceability — HireFlow
## Team 02 | Sprint #3 | Assignment 4.3

---

## Why Immutability Enables Safe Rollbacks

The artifact flow makes rollbacks safe because of one rule:

> **Images never change. A tag always refers to the same image.**

This means at any point, we can say:
- "Deploy the version from 2 days ago"
- "Restore the version that was running before the surge"
- "Show me what code is running right now"

All of these are trivially answerable with immutable, tagged images.

---

## HireFlow Rollback Scenarios

### Scenario 1: Bad form update breaks submission
```
Symptom:  Candidates report form submission errors after v2.4.1 deploy
Action:   kubectl rollout undo deployment/hireflow
Result:   Platform reverts to sha-7e2d45f (form v2.3.0) in ~60 seconds
```

### Scenario 2: New image causes memory spike
```
Symptom:  Pods OOMKilled after deploying sha-a3f91b2
Action:   kubectl set image deployment/hireflow \
            hireflow=ghcr.io/team02/hireflow:sha-7e2d45f
Result:   Stable image restored. Developer investigates memory issue.
```

### Scenario 3: Surge causes pod failures
```
Symptom:  Pods crashing under load during campus recruitment day
Action:   Check if issue is image-related or config-related
          kubectl describe pod <pod-name>  → check image tag
          If image is fine → check HPA config
          If image is bad  → rollback to previous tag
```

---

## Traceability: Connecting Everything

The artifact flow creates a complete chain of evidence:
```
Git Commit sha-a3f91b2
      │
      │ built by CI pipeline
      ▼
Docker Image ghcr.io/team02/hireflow:sha-a3f91b2
      │
      │ deployed to cluster
      ▼
Kubernetes Pod hireflow-6d8f9-xk2p1
      │
      │ serving requests to
      ▼
Candidate Application #APP-1042
      │
      │ submitted with
      ▼
Form Version v2.4.1

FULL CHAIN:
App #APP-1042 → Pod → Image sha-a3f91b2 → Commit → Form v2.4.1
```

This answers the recruiter's question in 30 seconds.

---

## Key Commands for Traceability
```bash
# What image is each pod running?
kubectl get pods -o wide -n recruitment

# Exact image tag for a specific pod
kubectl describe pod <pod-name> -n recruitment | grep Image

# Deployment rollout history
kubectl rollout history deployment/hireflow -n recruitment

# Rollback to previous version
kubectl rollout undo deployment/hireflow -n recruitment

# Rollback to specific revision
kubectl rollout undo deployment/hireflow --to-revision=2 -n recruitment

# Check rollout status after update
kubectl rollout status deployment/hireflow -n recruitment
```