# DevOps Workstation Setup — HireFlow
## Team 02 | Sprint #3 | Assignment 4.8

---

## Operating System

- **OS:** Windows 11
- **Terminal:** Git Bash (MINGW64)
- **Shell:** Bash via Git for Windows

---

## Tools Installed & Verified

### 1. Git — v2.x.x
**Purpose:** Source control, PR workflows, CI/CD triggers

**Verification command:**
```bash
git --version
```

**Why Git is essential for HireFlow:**
Git is the starting point of our entire CI/CD pipeline.
Every code change begins with a git push. Without Git:
- GitHub Actions cannot detect code changes
- No CI pipeline triggers
- No artifact build process starts
- No deployment to Kubernetes occurs

**Specific risk mitigated:**
Without Git version control, two developers working on the
HireFlow form schema simultaneously would overwrite each other's
changes. During campus hiring season, this could corrupt the
form version entirely — candidates would see inconsistent forms
with no way to trace what went wrong.

---

### 2. Docker Desktop — v29.2.1
**Purpose:** Build Docker images, run containers locally

**Verification commands:**
```bash
docker --version
docker run hello-world
```

**Why Docker is essential for HireFlow:**
Docker packages the HireFlow Node.js application with its
exact runtime into an immutable image. Without Docker:
- Cannot build hireflow-backend images locally
- Cannot test containers before pushing to Docker Hub
- Kubernetes has no image to pull and run
- "Works on my machine" problems reappear

**Specific risk mitigated:**
The HireFlow backend requires Node.js 18. Without Docker,
different team members running Node.js 14, 16, or 20 locally
would produce different behavior. A form submission bug that
only appears on Node.js 16 would be missed in local testing
and surface in production during a hiring surge.

---

### 3. kubectl — v1.34.1
**Purpose:** Communicate with Kubernetes clusters via CLI

**Verification command:**
```bash
kubectl version --client
kubectl get nodes
```

**Why kubectl is essential for HireFlow:**
kubectl is the command-line interface to the Kubernetes
API Server. Without kubectl:
- Cannot apply Deployment, Service, ConfigMap manifests
- Cannot check pod status after deployments
- Cannot retrieve logs when a pod crashes
- Cannot perform rollbacks when a bad image is deployed
- Cannot verify FORM_VERSION is injected correctly

**Specific risk mitigated:**
During a campus hiring surge, if pods enter CrashLoopBackOff
state, kubectl logs and kubectl describe are the primary
diagnostic tools. Without kubectl access, a team member
cannot determine whether the crash is caused by a missing
FORM_VERSION environment variable, an OOMKill from memory
pressure, or an application startup error.

---

### 4. kind — v0.22.0 (Kubernetes IN Docker)
**Purpose:** Run a local Kubernetes cluster inside Docker

**Verification commands:**
```bash
kind version
kind get clusters
kubectl cluster-info
kubectl get nodes
```

**Why kind is essential for HireFlow:**
kind creates a full Kubernetes cluster running inside Docker
containers on the local machine. Without kind:
- Cannot test Kubernetes manifests before pushing to CI/CD
- Cannot validate that Deployment, Service, ConfigMap work
- Cannot demonstrate rolling updates locally
- Cannot verify HPA configuration is syntactically correct

**Specific risk mitigated:**
Without a local cluster, a YAML indentation error in
k8s/deployment.yaml would only be discovered when the CD
pipeline runs against the production cluster. This would
cause a failed deployment during the hiring season.
With kind, the error is caught locally in seconds.

**Tool chosen over Minikube because:**
kind runs entirely inside Docker Desktop which was already
installed. It requires no additional VM, no additional
hypervisor configuration, and starts a cluster in under
2 minutes.

---

### 5. Helm — v3.14.0
**Purpose:** Kubernetes package manager — deploy applications
using reusable chart templates

**Verification command:**
```bash
helm version
```

**Why Helm is essential for HireFlow:**
Helm packages all Kubernetes manifests (Deployment, Service,
ConfigMap, HPA) into a single reusable chart. Without Helm:
- Cannot manage environment-specific configurations cleanly
  (dev vs staging vs production)
- Must manually edit YAML files for each environment
- Cannot version and rollback application configurations
- Cannot share deployment templates across team members

**Specific risk mitigated:**
Without Helm, deploying the HireFlow platform to a staging
environment before production requires manually copying and
editing all YAML files to change image tags, namespace names,
and replica counts. A missed edit deploys the wrong image
version to staging — meaning staging no longer reflects
what will run in production. This eliminates the value of
having a staging environment entirely.

---

### 6. Supporting CLI Tools

#### curl
**Purpose:** Test HTTP endpoints from terminal

**Verification:**
```bash
curl --version
```

**Specific use in HireFlow:**
After starting a container or port-forwarding to a pod,
curl http://localhost:3000/health verifies the /health
endpoint returns 200 OK before marking a deployment successful.

#### Bash (Git Bash / MINGW64)
**Purpose:** Execute shell scripts, run pipeline commands

**Specific use in HireFlow:**
All automation scripts (container-debug.sh, cluster-setup.sh,
registry-workflow.sh) are Bash scripts. Without Bash,
none of these scripts execute.

#### VS Code
**Purpose:** Write and edit Dockerfiles, YAML manifests,
GitHub Actions workflows, and application code

**Specific use in HireFlow:**
All Kubernetes manifests, Dockerfiles, and pipeline YAML
files are authored in VS Code with YAML syntax highlighting,
which catches indentation errors before they reach the cluster.

---

## Complete Tool Version Summary

| Tool | Version | Installation Method |
|------|---------|-------------------|
| Git | 2.x.x | Git for Windows |
| Docker Desktop | 29.2.1 | docker.com/desktop |
| kubectl | v1.34.1 | Direct binary download |
| kind | v0.22.0 | Direct binary download |
| Helm | v3.14.0 | Binary extracted from zip |
| curl | Built-in | Git Bash built-in |
| Bash | Built-in | Git Bash (MINGW64) |
| VS Code | Latest | code.visualstudio.com |

---

## PATH Configuration

All CLI tools (kubectl, kind, helm) are located at:
`C:\kubectl\`

Added to PATH via `~/.bashrc`:
```bash
export PATH=$PATH:/c/kubectl
```

This ensures all tools are accessible from any Git Bash
terminal session without specifying full paths.

---

## Local Kubernetes Cluster Status
```
Cluster name:    hireflow-local
Tool:            kind v0.22.0
Node:            hireflow-local-control-plane
Node status:     Ready
kubectl context: kind-hireflow-local
Namespace:       recruitment
```

HireFlow deployment verified:
- 3 pods running: abhich98/hireflow-backend:v2.4.1
- ConfigMap injected: FORM_VERSION=v2.4.1
- Service accessible via port-forward
- Health endpoint: 200 OK confirmed