# Cloud-Native Architecture Documentation — HireFlow Team 02

This folder documents cloud-native architecture decisions for
the HireFlow recruitment platform (Sprint #3, Assignment 4.17).

## Files

| File | Contents |
|------|---------|
| `kubernetes-architecture.md` | Why K8s, K8s responsibilities vs developer responsibilities, cloud-native architecture diagram, before vs after |

## Kubernetes Manifests

All manifests live in the `k8s/` folder:

| File | Purpose |
|------|---------|
| `k8s/namespace.yaml` | Isolates HireFlow in 'recruitment' namespace |
| `k8s/configmap.yaml` | Externalizes FORM_VERSION and app config |
| `k8s/deployment.yaml` | Declares 3 replicas, probes, resource limits |
| `k8s/service.yaml` | Stable ClusterIP + HPA for surge scaling |

## Apply Order (when cluster is ready)
```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

## Core Kubernetes Value for HireFlow

- **Surge scaling:** HPA auto-scales 2→10 pods during campus hiring
- **Form version tracing:** image tag v2.4.1 = exact form schema
- **Zero downtime:** rolling updates deploy new versions pod-by-pod
- **Self-healing:** crashed pods restarted in ~10 seconds automatically