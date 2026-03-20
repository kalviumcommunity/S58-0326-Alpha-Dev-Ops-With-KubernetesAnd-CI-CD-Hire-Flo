# DevOps Tools Guide — HireFlow
## Team 02 | Sprint #3 | Assignment 4.8

---

## Why Each Tool Exists in the DevOps Toolchain

Modern DevOps requires a specific set of tools that work
together as a chain. Each tool owns a specific responsibility.
Removing any single tool breaks the chain.
```
CODE CHANGE
    │
    │ git push
    ▼
GIT ──────────────────────────────────────────────────────
Tracks every change. Triggers CI/CD via webhooks.
Without Git: No version history. No CI triggers. No rollback.
    │
    │ GitHub Actions detects push
    ▼
CI RUNNER (ubuntu-latest)
    │
    │ docker build
    ▼
DOCKER ───────────────────────────────────────────────────
Packages application + runtime into immutable image.
Without Docker: No portable artifact. No consistent environments.
    │
    │ docker push → Docker Hub
    │ kubectl apply
    ▼
KUBECTL ──────────────────────────────────────────────────
Sends desired state to Kubernetes API Server.
Without kubectl: Cannot deploy, debug, or rollback.
    │
    │ cluster receives manifests
    ▼
KIND (Local) / Cloud K8s (Production) ───────────────────
Runs and manages containers. Self-heals failures.
Without cluster: No orchestration. No scaling. No self-healing.
    │
    │ helm install / helm upgrade
    ▼
HELM ─────────────────────────────────────────────────────
Manages environment-specific configurations.
Without Helm: Manual YAML editing per environment. Error-prone.
    │
    │ curl http://localhost:3000/health
    ▼
CURL ─────────────────────────────────────────────────────
Validates endpoints after deployment.
Without curl: Cannot verify deployment succeeded.
```

---

## Installation Paths on This Workstation
```
C:\kubectl\
├── kubectl.exe    ← Kubernetes CLI
├── kind.exe       ← Local cluster tool
└── helm.exe       ← Package manager

PATH entry in ~/.bashrc:
export PATH=$PATH:/c/kubectl
```

---

## Common Commands Reference

### Git
```bash
git --version                    # Verify installation
git log --oneline -5             # Recent commits
git checkout -b assignment-X     # Create feature branch
git push origin branch-name      # Push to GitHub (triggers CI)
```

### Docker
```bash
docker --version                 # Verify installation
docker run hello-world           # Test runtime
docker build -t hireflow:local . # Build image
docker images                    # List images
docker ps                        # Running containers
docker logs container-name       # View container logs
```

### kubectl
```bash
kubectl version --client         # Verify installation
kubectl get nodes                # Cluster health
kubectl get pods -n recruitment  # HireFlow pods
kubectl logs pod-name -n recruitment  # Pod logs
kubectl describe pod name -n recruitment  # Pod events
kubectl apply -f k8s/            # Deploy manifests
kubectl rollout undo deployment/hireflow  # Rollback
```

### kind
```bash
kind version                     # Verify installation
kind create cluster --name hireflow-local  # Create cluster
kind get clusters                # List clusters
kind delete cluster --name hireflow-local  # Delete cluster
```

### Helm
```bash
helm version                     # Verify installation
helm list -n recruitment         # Installed releases
helm install hireflow ./charts/  # Install chart
helm upgrade hireflow ./charts/  # Upgrade release
helm rollback hireflow 1         # Rollback to revision 1
```

### curl
```bash
curl http://localhost:3000/health           # Health check
curl http://localhost:3000/api/form-version # Form version
curl -s -o /dev/null -w "%{http_code}" URL  # Status code only
```

---

## Troubleshooting Common Issues

### Docker Desktop not starting
```
Symptom: docker: command not found
Fix:     Open Docker Desktop → wait for "Engine running" green dot
```

### kubectl cannot connect to cluster
```
Symptom: The connection to the server was refused
Fix:     kind create cluster --name hireflow-local
         kubectl config use-context kind-hireflow-local
```

### helm: command not found
```
Symptom: bash: helm: command not found
Fix:     Verify /c/kubectl/helm.exe exists
         source ~/.bashrc
         helm version
```

### kind cluster deleted after restart
```
Symptom: kubectl get nodes shows error
Fix:     kind create cluster --name hireflow-local
         kubectl apply -f k8s/
```