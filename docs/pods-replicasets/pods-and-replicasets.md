# Pods and ReplicaSets — HireFlow
## Team 02 | Sprint #3 | Assignment 4.20

---

## What is a Pod?

A Pod is the smallest deployable unit in Kubernetes.
It is a wrapper around one or more containers that share:
- The same network namespace (one IP address)
- The same storage volumes
- The same lifecycle
```
POD: hireflow-pod
┌─────────────────────────────────────────┐
│  IP: 10.244.0.x (assigned by cluster)  │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  Container: hireflow-container  │    │
│  │  Image: abhich98/hireflow:v2.4.1│    │
│  │  Port: 3000                     │    │
│  │  FORM_VERSION: v2.4.1           │    │
│  │  PID 1: node server.js          │    │
│  └─────────────────────────────────┘    │
│                                         │
│  Volumes: (none for this pod)           │
│  Restart Policy: Always                 │
└─────────────────────────────────────────┘
```

### Why NOT Use Standalone Pods in Production
```
STANDALONE POD PROBLEM:

kubectl apply -f hireflow-pod.yaml
→ Pod created ✅

Pod crashes (Node.js error)
→ Pod stays in Error/CrashLoopBackOff state
→ Nobody creates a replacement
→ Application is DOWN ❌

kubectl delete pod hireflow-pod
→ Pod deleted
→ Nobody creates it again
→ Application is DOWN ❌

CONCLUSION:
Standalone pods have NO self-healing.
They are only useful for:
  - One-off debugging tasks
  - Running a command inside the cluster
  - Learning purposes (this assignment)
```

---

## What is a ReplicaSet?

A ReplicaSet ensures that a specified number of pod
replicas are always running.
```
REPLICASET: hireflow-rs
┌─────────────────────────────────────────────────────┐
│  Desired replicas: 3                                │
│  Current replicas: 3                                │
│  Selector: app=hireflow-rs                          │
│                                                     │
│  ┌──────────────┐ ┌──────────────┐ ┌─────────────┐ │
│  │  Pod 1       │ │  Pod 2       │ │  Pod 3      │ │
│  │  app=        │ │  app=        │ │  app=       │ │
│  │  hireflow-rs │ │  hireflow-rs │ │  hireflow-rs│ │
│  │  Running ✅  │ │  Running ✅  │ │  Running ✅ │ │
│  └──────────────┘ └──────────────┘ └─────────────┘ │
└─────────────────────────────────────────────────────┘

Pod 2 crashes ❌
ReplicaSet detects: current=2, desired=3
ReplicaSet creates Pod 4 automatically
→ Back to 3 pods in ~10 seconds ✅
```

---

## Pod vs ReplicaSet — Side by Side
```
ASPECT          STANDALONE POD        REPLICASET
──────────────  ────────────────────  ──────────────────────
Count           Always 1              N replicas (configurable)
Self-healing    ❌ No                 ✅ Yes (auto-recreates)
Scaling         ❌ Manual only        ✅ kubectl scale
Use case        Debugging, learning   Production workloads
Crash recovery  Stays crashed         New pod in ~10s
Deletion        Gone forever          RS recreates it
```

---

## YAML Desired State Explained
```yaml
spec:
  replicas: 3          # DESIRED STATE: "I want 3 pods"
  selector:
    matchLabels:
      app: hireflow-rs # "Manage pods with this label"
  template:            # "When creating pods, use this blueprint"
    metadata:
      labels:
        app: hireflow-rs  # Must match selector
    spec:
      containers:
      - image: abhich98/hireflow-backend:v2.4.1
```

Kubernetes control loop:
```
Every few seconds:
  count = count pods with label app=hireflow-rs
  if count < 3: create new pods using template
  if count > 3: delete excess pods
  if count = 3: do nothing ✅
```

---

## Self-Healing Demonstration
```bash
# Before: 3 pods running
kubectl get pods -n recruitment -l app=hireflow-rs

# Delete one pod (simulates crash)
kubectl delete pod <pod-name> -n recruitment

# After: RS immediately creates replacement
kubectl get pods -n recruitment -l app=hireflow-rs
# New pod appears in ~10 seconds
```

---

## Scaling Demonstration
```bash
# Scale up for hiring surge
kubectl scale replicaset hireflow-rs \
  --replicas=5 -n recruitment

# Scale down after surge
kubectl scale replicaset hireflow-rs \
  --replicas=2 -n recruitment

# Restore normal
kubectl scale replicaset hireflow-rs \
  --replicas=3 -n recruitment
```

---

## Why Production Uses Deployments Instead
```
ReplicaSet:
  ✅ Self-healing
  ✅ Scaling
  ❌ No rolling updates
  ❌ No rollback history
  ❌ Updating image requires manual RS deletion

Deployment (wraps ReplicaSet):
  ✅ Self-healing (via ReplicaSet)
  ✅ Scaling (via ReplicaSet)
  ✅ Rolling updates (pod by pod, zero downtime)
  ✅ Rollback history
  ✅ Update image → new RS created automatically

For HireFlow:
  We use Deployment in k8s/deployment.yaml (Assignment 4.17)
  The Deployment automatically creates and manages a ReplicaSet
  This assignment creates a ReplicaSet directly for learning
```