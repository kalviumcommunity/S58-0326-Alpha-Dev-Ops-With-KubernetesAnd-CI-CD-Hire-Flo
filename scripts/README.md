# Local Cluster Documentation — HireFlow Team 02

This folder documents the local Kubernetes cluster setup for
the HireFlow recruitment platform (Sprint #3, Assignment 4.19).

## Tool Used: kind (Kubernetes IN Docker)

## Files

| File | Contents |
|------|---------|
| `kind-setup-guide.md` | Why kind, installation steps, verification commands, daily usage, local vs production comparison |

## Setup Script

| File | Location | Purpose |
|------|----------|---------|
| `cluster-setup.sh` | `scripts/` | Full automated setup: verify prereqs, create cluster, deploy HireFlow, test via port-forward |

## Quick Start
```bash
# Make sure Docker Desktop is running first
bash scripts/cluster-setup.sh
```

## Manual Commands
```bash
# Create cluster
kind create cluster --name hireflow-local

# Deploy HireFlow
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Check pods
kubectl get pods -n recruitment

# Test via port-forward
kubectl port-forward -n recruitment \
  service/hireflow-service 8080:80
curl http://localhost:8080/health
```

## Cluster Info

- **Tool:** kind v0.22.0
- **Cluster name:** hireflow-local
- **kubectl context:** kind-hireflow-local
- **Namespace:** recruitment
- **Pods:** 3 replicas of hireflow-backend:v2.4.1