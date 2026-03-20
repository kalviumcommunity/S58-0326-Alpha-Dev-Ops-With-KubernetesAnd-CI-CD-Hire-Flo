# Local Kubernetes Cluster Setup — kind
## HireFlow | Team 02 | Sprint #3 | Assignment 4.19

---

## Tool Chosen: kind (Kubernetes IN Docker)

### Why kind over Minikube or k3s?

| Tool | Pros | Cons |
|------|------|------|
| **kind** ✅ | Works inside Docker Desktop (already installed), fast startup, lightweight, multi-node support | Requires Docker |
| Minikube | Easy GUI, addons | Needs VM or Docker, heavier |
| k3s | Lightweight, closest to production | Linux-native, harder on Windows |

**kind was chosen because:**
- Docker Desktop already installed and running
- No additional VM needed — kind runs inside Docker containers
- Fast cluster creation (~2 minutes)
- Lightweight — doesn't slow down the laptop
- Supports multiple nodes (simulates real cluster)

---

## Prerequisites
```
✅ Docker Desktop — running (Engine: green)
✅ kubectl      — installed (v1.29.0)
✅ kind         — installed (v0.22.0)
✅ Git Bash     — for running commands
```

---

## Installation Steps

### 1. Install kubectl
```bash
curl -LO "https://dl.k8s.io/release/v1.29.0/bin/windows/amd64/kubectl.exe"
mkdir -p /c/kubectl
mv kubectl.exe /c/kubectl/
echo 'export PATH=$PATH:/c/kubectl' >> ~/.bashrc
source ~/.bashrc
kubectl version --client
```

### 2. Install kind
```bash
curl -Lo kind.exe https://kind.sigs.k8s.io/dl/v0.22.0/kind-windows-amd64
mv kind.exe /c/kubectl/
kind version
```

### 3. Create the HireFlow cluster
```bash
kind create cluster --name hireflow-local
```

---

## Cluster Verification Commands
```bash
# Confirm cluster is running
kubectl cluster-info

# Check node status
kubectl get nodes
# Expected: hireflow-local-control-plane   Ready

# Check all system pods
kubectl get pods -A

# Check active context
kubectl config current-context
# Expected: kind-hireflow-local

# List kind clusters
kind get clusters
# Expected: hireflow-local
```

---

## Deploying HireFlow to Local Cluster
```bash
# Apply all manifests in order
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml

# Watch pods start
kubectl get pods -n recruitment -w

# Verify all resources
kubectl get all -n recruitment
```

---

## Useful Daily Commands
```bash
# Check cluster is still running
kubectl get nodes

# See HireFlow pod status
kubectl get pods -n recruitment

# See pod logs
kubectl logs -n recruitment <pod-name>

# Describe a pod (events, config)
kubectl describe pod -n recruitment <pod-name>

# Check form version in configmap
kubectl get configmap hireflow-config \
  -n recruitment -o yaml

# Check form version in running pod
kubectl exec -n recruitment <pod-name> \
  -- env | grep FORM_VERSION

# Forward pod port to localhost for testing
kubectl port-forward -n recruitment \
  service/hireflow-service 8080:80

# Then test: curl http://localhost:8080/health
```

---

## Cluster Management
```bash
# Stop cluster (saves resources when not in use)
kind delete cluster --name hireflow-local

# Recreate cluster
kind create cluster --name hireflow-local

# List all contexts
kubectl config get-contexts

# Switch context if multiple clusters
kubectl config use-context kind-hireflow-local
```

---

## Why Local Cluster for HireFlow?
```
LOCAL CLUSTER PURPOSE:
  Test Kubernetes manifests before pushing to CI/CD
  Validate rolling updates work correctly
  Debug pod scheduling and probe issues
  Test HPA behavior (simulated)
  Verify ConfigMap injection works
  Practice kubectl debugging commands

WHAT IT REPLACES:
  Before: "I think my YAML is correct"
  After:  "I deployed it locally and confirmed it works"

WHAT IT DOES NOT REPLACE:
  Production cloud cluster (AWS EKS, Azure AKS, GKE)
  Full HPA testing (needs metrics server)
  Multi-region deployment testing
  Load testing at scale
```

---

## Local Cluster vs Production Cluster

| Aspect | kind (Local) | Cloud K8s (Production) |
|--------|-------------|----------------------|
| Purpose | Development, testing | Real workloads |
| Nodes | 1 node (Docker container) | Multiple VMs |
| HPA | Limited (no metrics server by default) | Full support |
| Persistence | Deleted on cluster delete | Persistent volumes |
| Access | Local machine only | Internet accessible |
| Cost | Free | Paid (cloud resources) |
| Setup time | 2 minutes | 15-30 minutes |