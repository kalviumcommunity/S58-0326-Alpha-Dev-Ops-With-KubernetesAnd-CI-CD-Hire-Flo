# Pod States & Failure Reference — HireFlow
## Team 02 | Sprint #3 | Assignment 4.4

---

## Complete Pod State Diagram
```
                    kubectl apply
                         │
                         ▼
                      Pending
                    (being scheduled)
                         │
              ┌──────────┴──────────┐
              │                     │
        Scheduled ✅           Unschedulable ❌
              │                     │
              ▼                     ▼
      ContainerCreating        Stays Pending
      (image pulling)          Fix: check resources
              │
        ┌─────┴──────┐
        │            │
   Pull OK ✅    ImagePullBackOff ❌
        │            │
        ▼            ▼
      Running    Fix: check image tag
        │         and registry auth
   ┌────┴────┐
   │         │
Healthy ✅  Probe Fails ❌
   │         │
   │    ┌────┴────────┐
   │    │             │
   │  Liveness    Readiness
   │  fails       fails
   │    │             │
   │  Restart    Removed from
   │    │        load balancer
   │    │
   │  CrashLoopBackOff
   │  (if keeps failing)
   │
OOMKilled ❌
(memory limit exceeded)
```

---

## Failure States — Quick Diagnosis Guide

### CrashLoopBackOff
```
What it means:
  Container starts → crashes → K8s restarts → crashes again
  K8s increases wait time between restarts (backoff)
  0s → 10s → 20s → 40s → 80s → 160s → 300s (max)

How to diagnose:
  kubectl logs hireflow-pod-xyz -n recruitment
  kubectl logs hireflow-pod-xyz -n recruitment --previous

Common causes for HireFlow:
  1. Missing FORM_VERSION env var → app crashes on startup
  2. Port already in use → server fails to bind
  3. Wrong CMD in Dockerfile → command not found
  4. Syntax error in server.js → Node.js exits immediately

Fix example (missing env var):
  Add env var to deployment.yaml:
  env:
  - name: FORM_VERSION
    value: "v2.4.1"
```

### ImagePullBackOff
```
What it means:
  Kubernetes cannot pull the container image from registry

How to diagnose:
  kubectl describe pod hireflow-pod-xyz -n recruitment
  Look at Events section for pull error details

Common causes:
  1. Wrong image tag: abhich98/hireflow-backend:v9.9.9 (doesn't exist)
  2. Registry auth missing (private registry needs imagePullSecret)
  3. No internet access from cluster nodes
  4. Typo in image name

Fix:
  Verify image exists: docker pull abhich98/hireflow-backend:v2.4.1
  Update deployment.yaml with correct tag
  kubectl apply -f k8s/deployment.yaml
```

### OOMKilled
```
What it means:
  Pod used more memory than its limit → terminated immediately

How to diagnose:
  kubectl describe pod hireflow-pod-xyz
  Look for: "Last State: Terminated  Reason: OOMKilled"

Common causes for HireFlow:
  1. Memory limit set too low (256Mi not enough during surge)
  2. Memory leak in application code
  3. Processing too many requests simultaneously

Fix options:
  Option A: Increase memory limit
    resources:
      limits:
        memory: "512Mi"   ← increase from 256Mi

  Option B: Let HPA scale more pods
    More pods = less load per pod = less memory per pod
```

### Pending (Not Scheduling)
```
What it means:
  Pod created but Scheduler cannot place it on any node

How to diagnose:
  kubectl describe pod hireflow-pod-xyz
  Look for Events: "0/1 nodes are available: Insufficient memory"

Common causes:
  1. All nodes are full (requests too high)
  2. Node selector doesn't match any node
  3. Resource quota exceeded in namespace

Fix:
  Lower resource requests OR add more nodes to cluster
  During local development with kind: cluster has limited resources
```

---

## Rollout State Diagnosis
```bash
# Check current rollout status
kubectl rollout status deployment/hireflow -n recruitment

# View rollout history
kubectl rollout history deployment/hireflow -n recruitment

# Rollback to previous version
kubectl rollout undo deployment/hireflow -n recruitment

# Rollback to specific revision
kubectl rollout undo deployment/hireflow --to-revision=2 -n recruitment

# Pause a rollout (manual intervention)
kubectl rollout pause deployment/hireflow -n recruitment

# Resume a paused rollout
kubectl rollout resume deployment/hireflow -n recruitment
```

---

## Self-Healing Validation Commands
```bash
# Simulate pod crash — delete a pod manually
# K8s should recreate it within 10 seconds
kubectl delete pod <pod-name> -n recruitment

# Watch pods in real time
kubectl get pods -n recruitment -w

# Check ReplicaSet is maintaining desired count
kubectl get replicasets -n recruitment

# Check HPA status during surge
kubectl get hpa -n recruitment

# Check events for a deployment
kubectl describe deployment hireflow -n recruitment
```