# Kubernetes Lifecycle Documentation — HireFlow Team 02

This folder documents the Kubernetes application lifecycle for the
HireFlow recruitment platform (Sprint #3, Assignment 4.4).

## Files

| File | Contents |
|------|---------|
| `k8s-lifecycle-concepts.md` | Full lifecycle: pod creation, ReplicaSets, rolling updates, probes, resources, pod states, self-healing |
| `hireflow-k8s-deployment.yaml` | Complete K8s manifest: Deployment, ConfigMap, Service, HPA |
| `pod-states-reference.md` | Pod state diagram, failure diagnosis guide, rollout commands |

## The Kubernetes Lifecycle for HireFlow
```
kubectl apply
      │
      ▼
Deployment → ReplicaSet → Pods → Scheduled → Running → Healthy ✅
      │
      └── Self-healing: crashes restarted, surges scaled, updates rolled
```

## Key Concepts

| Concept | HireFlow Application |
|---------|---------------------|
| ReplicaSet | Maintains 3 pods, scales to 10 via HPA during surges |
| Rolling Update | Zero-downtime form version updates (v2.3.0 → v2.4.1) |
| Liveness Probe | Restarts hung Node.js process |
| Readiness Probe | Prevents traffic to starting pods |
| Resource Limits | OOMKill prevention during high submission load |
| ConfigMap | FORM_VERSION injected without image rebuild |