# CI/CD Artifact Flow — Source → Image → Registry → Cluster
## HireFlow | Team 02 | Sprint #3 | Assignment 4.3

---

## The Big Picture

In DevOps, code is NEVER deployed directly to a server.
Every change is first transformed into an immutable artifact,
stored safely, and only then deployed to the cluster.

The complete flow for HireFlow looks like this:
```
Developer Workstation
        │
        │  git push / Pull Request merged
        ▼
┌─────────────────────────────────────────────────────────┐
│                  STAGE 1: SOURCE                        │
│                                                         │
│  Git Repository (GitHub)                                │
│  Branch: main                                           │
│  Commit: sha-a3f91b2                                    │
│  Changed: Application form field added (v2.4.1)         │
└───────────────────────┬─────────────────────────────────┘
                        │ Triggers GitHub Actions
                        ▼
┌─────────────────────────────────────────────────────────┐
│                  STAGE 2: CI PIPELINE                   │
│                                                         │
│  GitHub Actions Runner (Ubuntu Linux)                   │
│  Step 1: Checkout source code                           │
│  Step 2: npm install (install dependencies)             │
│  Step 3: npm test (run automated tests)                 │
│  Step 4: docker build (create image)                    │
│  Step 5: Tag image with Git SHA                         │
└───────────────────────┬─────────────────────────────────┘
                        │ Produces artifact
                        ▼
┌─────────────────────────────────────────────────────────┐
│                  STAGE 3: DOCKER IMAGE                  │
│                                                         │
│  Image: ghcr.io/team02/hireflow:sha-a3f91b2             │
│  Contains:                                              │
│    - HireFlow Node.js application code                  │
│    - Node.js 18 runtime                                 │
│    - All npm dependencies                               │
│    - FORM_VERSION=v2.4.1 (environment config)           │
│                                                         │
│  IMMUTABLE: This image never changes after build        │
└───────────────────────┬─────────────────────────────────┘
                        │ docker push
                        ▼
┌─────────────────────────────────────────────────────────┐
│                  STAGE 4: REGISTRY                      │
│                                                         │
│  GitHub Container Registry (GHCR)                       │
│  ghcr.io/team02/hireflow                                │
│                                                         │
│  Stored versions:                                       │
│  ├── sha-a3f91b2  ← form v2.4.1 (latest)               │
│  ├── sha-7e2d45f  ← form v2.3.0                         │
│  └── sha-1c8a90b  ← form v2.2.5                         │
│                                                         │
│  Full history preserved. Any version pullable anytime.  │
└───────────────────────┬─────────────────────────────────┘
                        │ kubectl apply
                        ▼
┌─────────────────────────────────────────────────────────┐
│                  STAGE 5: KUBERNETES CLUSTER            │
│                                                         │
│  Deployment: hireflow                                   │
│  Image: ghcr.io/team02/hireflow:sha-a3f91b2             │
│  Replicas: 3 (scales to 10 via HPA during surges)       │
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │  Pod 1   │  │  Pod 2   │  │  Pod 3   │              │
│  │sha-a3f91b│  │sha-a3f91b│  │sha-a3f91b│              │
│  └──────────┘  └──────────┘  └──────────┘              │
│                                                         │
│  All pods run IDENTICAL image — no version drift        │
└─────────────────────────────────────────────────────────┘
```

---

## Stage-by-Stage Explanation

### Stage 1: Source Code (Git Commit)

The artifact flow begins with a Git commit.

For HireFlow, a typical trigger is:
- Developer adds a new field to the application form (version v2.4.1)
- Developer pushes to a feature branch
- PR is reviewed and merged into `main`
- The merge commit (`sha-a3f91b2`) becomes the unique identifier
  for everything that follows

**Key idea:** The commit hash is the DNA of the entire deployment.
Every image, every pod, every running container traces back to it.
```bash
# The commit that starts everything
git log --oneline -1
# Output: a3f91b2 feat(form): add github profile field for v2.4.1
```

---

### Stage 2: CI Pipeline (Code → Artifact)

GitHub Actions detects the push to `main` and triggers the pipeline.

The pipeline does NOT deploy code.
The pipeline PRODUCES an artifact (Docker image).
```yaml
# Simplified view of what happens in .github/workflows/ci-cd.yml
- checkout code          # Get the source at commit sha-a3f91b2
- npm install            # Install dependencies
- npm test               # Validate the code works
- docker build           # Package everything into an image
- tag with git sha       # ghcr.io/team02/hireflow:sha-a3f91b2
- push to registry       # Store in GHCR
```

**Key idea:** If tests fail, the pipeline stops here.
No broken image is ever created or deployed.

---

### Stage 3: Docker Image (The Immutable Artifact)

The Docker image is a frozen snapshot of:
```
┌─────────────────────────────────┐
│  ghcr.io/team02/hireflow        │
│  Tag: sha-a3f91b2               │
│  ─────────────────────────────  │
│  Application Layer              │
│  → HireFlow source code         │
│  → Form schema v2.4.1           │
│                                 │
│  Dependency Layer               │
│  → node_modules (npm packages)  │
│                                 │
│  Runtime Layer                  │
│  → Node.js 18.x                 │
│                                 │
│  Base Layer                     │
│  → node:18-alpine (Linux)       │
└─────────────────────────────────┘
```

**Immutability rule:**
Once built with tag `sha-a3f91b2`, this image NEVER changes.
If a bug is found, a new commit creates a new image with a new tag.
The old image remains unchanged in the registry.

This is why "it works in staging but not production" becomes
impossible — both environments pull the exact same image.

---

### Stage 4: Container Registry (The Artifact Store)

The registry is the central distribution point.

For HireFlow we use **GitHub Container Registry (GHCR)**:
- URL: `ghcr.io/team02/hireflow`
- Access: controlled via GitHub token
- History: every image version preserved

**Image Tags vs Image Digests:**
```
TAG (human-friendly label):
ghcr.io/team02/hireflow:sha-a3f91b2
→ Easy to read, maps to a commit

DIGEST (cryptographic fingerprint):
ghcr.io/team02/hireflow@sha256:4f8b...
→ Exact byte-for-byte identity of the image
→ Cannot be spoofed or accidentally overwritten
```

**Why the registry solves HireFlow's form version problem:**
```
Recruiter question: "Which form did candidate #APP-1042 fill out?"

Answer process:
1. Look up submission timestamp → Oct 3, 2026 10:32 AM
2. Check what image was deployed at that time → sha-a3f91b2
3. Check registry → sha-a3f91b2 = form schema v2.4.1
4. Confirmed: candidate saw form v2.4.1

Without registry + image tagging: impossible to answer this question.
With registry + image tagging: answered in 30 seconds.
```

---

### Stage 5: Kubernetes Cluster (Running the Artifact)

Kubernetes NEVER builds code. It only runs pre-built images.

The deployment manifest specifies exactly which image to run:
```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hireflow
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: hireflow
        image: ghcr.io/team02/hireflow:sha-a3f91b2
        # ↑ Exact image tag — no ambiguity
```

Kubernetes then:
1. Pulls `sha-a3f91b2` from GHCR
2. Starts 3 pods from that image
3. All pods are byte-for-byte identical
4. Health checks confirm pods are ready
5. Traffic is routed to healthy pods

---

## Why This Flow Enables Safe Rollbacks

The single most important operational benefit of this flow:
```
ROLLBACK SCENARIO:

v2.4.1 deployed → recruiters report form broken
                  (sha-a3f91b2 has a bug)

Rollback steps:
1. Identify last stable image: sha-7e2d45f (form v2.3.0)
2. Update deployment:
   kubectl rollout undo deployment/hireflow
   OR
   kubectl set image deployment/hireflow \
     hireflow=ghcr.io/team02/hireflow:sha-7e2d45f

3. Kubernetes rolls back pod by pod
4. Within 60 seconds — stable version is running again

Why this works:
✅ sha-7e2d45f still exists in GHCR (registry preserves history)
✅ Image is immutable (identical to what ran before)
✅ No rebuilding required
✅ No "it worked yesterday" mystery
```

---

## Build Time vs Run Time — Critical Distinction
```
BUILD TIME (CI Pipeline)              RUN TIME (Kubernetes)
─────────────────────────             ─────────────────────
When: On every git push               When: After image is pulled
Where: GitHub Actions runner          Where: Kubernetes worker nodes
What happens:                         What happens:
  - Source code compiled                - Image layers extracted
  - Dependencies installed              - Container process started
  - Tests executed                      - Health checks run
  - Image created + tagged              - Traffic routed to pod
  - Image pushed to registry

Output: Docker image artifact         Output: Running application

KEY RULE: If it's not in the image,   KEY RULE: Kubernetes only runs
it doesn't exist at run time          what was built at build time
```

---

## Tracing a Running Container Back to Its Git Commit

This is the ultimate test of understanding:
```bash
# 1. Find running pod
kubectl get pods -n recruitment
# Output: hireflow-6d8f9-xk2p1

# 2. Check what image it's running
kubectl describe pod hireflow-6d8f9-xk2p1 -n recruitment | grep Image
# Output: Image: ghcr.io/team02/hireflow:sha-a3f91b2

# 3. Trace image tag back to Git commit
git show sha-a3f91b2 --stat
# Output: commit a3f91b2
#         feat(form): add github profile field for form v2.4.1

# 4. You now know EXACTLY what code is running in production
```

**If you can do this — you understand the artifact flow.**