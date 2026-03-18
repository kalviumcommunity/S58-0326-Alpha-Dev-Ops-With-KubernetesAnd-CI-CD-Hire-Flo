# Cluster Architecture Documentation — HireFlow Team 02

This folder documents Kubernetes cluster architecture for the
HireFlow recruitment platform (Sprint #3, Assignment 4.18).

## Files

| File | Contents |
|------|---------|
| `cluster-architecture.md` | Full cluster diagram, control plane components (API Server, etcd, Scheduler, Controller Manager), worker node components (kubelet, kube-proxy, containerd), interaction flows |
| `component-reference.md` | Quick reference table, failure impact analysis, HireFlow component mapping, scenario Q&A |

## Cluster Structure Summary
```
CONTROL PLANE (Brain)          WORKER NODES (Muscle)
─────────────────────          ─────────────────────
API Server    → entry point    kubelet    → runs pods
etcd          → stores state   kube-proxy → routes traffic
Scheduler     → places pods    containerd → runs containers
Controller Mgr→ self-healing
```

## Key Insight for HireFlow

Every time a HireFlow pod crashes and recovers in ~10 seconds,
ALL of these components worked together:

kubelet detected crash →
API Server received report →
etcd updated state →
Controller Manager created replacement →
Scheduler assigned to node →
kubelet started new container →
containerd pulled image →
kube-proxy updated routing →
Pod serving traffic again ✅