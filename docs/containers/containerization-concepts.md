# Containerization Concepts — HireFlow Recruitment Platform
## Team 02 | Sprint #3 | Assignment 4.12

---

## Why Containers Were Needed for HireFlow

Before containerization, the HireFlow recruitment platform faced three 
critical operational problems:

### Problem 1: Environment Inconsistency
A developer builds the application on Windows with Node.js 16.
The CI pipeline runs on Ubuntu with Node.js 18.
Production runs on a server with Node.js 14.

Result: "It works on my machine" — but breaks everywhere else.
During campus hiring season, this inconsistency caused unpredictable
failures that were impossible to reproduce and debug quickly.

### Problem 2: Slow, Heavy Deployments
Traditional server deployments required:
- Provisioning a new VM (5–10 minutes)
- Installing OS dependencies
- Configuring environment variables manually
- Deploying application files

When the platform needed to scale during a hiring surge, this process
was far too slow. By the time new servers were ready, the surge had
already caused downtime.

### Problem 3: Form Version Drift
Without containers, different servers could be running different
versions of the application code and form schemas simultaneously
with no reliable way to enforce consistency.

---

## What a Container Actually Is

A container is a **lightweight, portable, self-contained unit** that
packages an application together with everything it needs to run:

┌─────────────────────────────────────┐
│           CONTAINER                 │
│  ┌─────────────────────────────┐    │
│  │     Your Application        │    │
│  │   (HireFlow Node.js API)    │    │
│  ├─────────────────────────────┤    │
│  │   Runtime Dependencies      │    │
│  │   (Node.js 18, npm pkgs)    │    │
│  ├─────────────────────────────┤    │
│  │   Environment Config        │    │
│  │   (FORM_VERSION=v2.4.1)     │    │
│  └─────────────────────────────┘    │
│                                     │
│  Shares Host OS Kernel              │
└─────────────────────────────────────┘

Key characteristics:
- **Portable** — runs identically on any machine that has a container runtime
- **Isolated** — processes, filesystem, and network are isolated from the host
- **Lightweight** — shares the host OS kernel, no full guest OS needed
- **Fast** — starts in seconds, not minutes
- **Immutable** — the image is fixed; changes require building a new image

---

## Containers vs Virtual Machines

This is one of the most important distinctions in modern DevOps.

VIRTUAL MACHINE                         CONTAINER
┌──────────────────────┐               ┌──────────────────────┐
│      App A           │               │      App A           │
├──────────────────────┤               ├──────────────────────┤
│   Guest OS (Linux)   │               │  App Dependencies    │
│   (Full OS copy)     │               │  (libs, runtime)     │
├──────────────────────┤               ├──────────────────────┤
│    Hypervisor        │               │  Container Runtime   │
│  (VMware, HyperV)    │               │  (Docker, containerd)│
├──────────────────────┤               ├──────────────────────┤
│   Host OS (Linux)    │               │   Host OS (Linux)    │
├──────────────────────┤               ├──────────────────────┤
│   Physical Hardware  │               │   Physical Hardware  │
└──────────────────────┘               └──────────────────────┘

| Comparison Point | Virtual Machine | Container |
|-----------------|-----------------|-----------|
| Startup Time | 1–5 minutes | 1–5 seconds |
| Size | GBs (full OS) | MBs (app + deps only) |
| OS | Full guest OS per VM | Shares host OS kernel |
| Isolation Level | Strong (hardware-level) | Process-level |
| Resource Usage | Heavy (CPU + RAM per VM) | Lightweight |
| Portability | Limited (hypervisor-dependent) | High (runs anywhere) |
| Density | Few VMs per host | Hundreds of containers |
| Best For | Legacy apps, strong isolation | Microservices, CI/CD, K8s |

### What This Means for HireFlow

During campus hiring surges, we need to scale from 2 to 10 instances
of the application rapidly. With VMs, each new instance takes minutes
to provision. With containers, Kubernetes can spin up a new pod in
under 10 seconds — fast enough to handle the surge in real time.

---

## How Containers Work Internally

Containers use two core Linux kernel features:

### 1. Namespaces (Isolation)
Namespaces isolate what a container can see:
- **PID namespace** — container sees only its own processes
- **Network namespace** — container has its own network interfaces
- **Filesystem namespace** — container has its own root filesystem
- **User namespace** — container has its own user/group IDs

### 2. Control Groups / cgroups (Resource Limits)
cgroups limit what a container can use:
- Max CPU cores
- Max memory (RAM)
- Max disk I/O

This is exactly what Kubernetes `resources.requests` and
`resources.limits` control in our deployment manifests.

---

## Container Images vs Running Containers

This distinction is critical and often confused by beginners:

Container IMAGE                    Running CONTAINER
(Blueprint / Template)             (Instance / Process)Like a recipe                  →   Like the cooked meal
Like a class definition        →   Like an object instance
Like a stopped VM snapshot     →   Like a running VMdocker build → creates IMAGE
docker run   → creates CONTAINER from IMAGE

For HireFlow:
- The **image** is built once in CI pipeline with a Git SHA tag
- Multiple **containers** (pods) run from the same image in Kubernetes
- All pods run identical code — no version drift possible

---

## The Image Registry: Distribution Mechanism

```
Developer           CI Pipeline          Registry           Kubernetes
    │                    │                   │                   │
    │── git push ───────>│                   │                   │
    │                    │── build image ──> │                   │
    │                    │── push image ───> │                   │
    │                    │   (sha-a3f91b2)   │                   │
    │                    │                   │                   │
    │                    │                   │<── pull image ───│
    │                    │                   │─── serve image ──>│
    │                    │                   │                   │── run container
```

For HireFlow, images are pushed to **GitHub Container Registry (GHCR)**
with the Git SHA as the tag. Kubernetes pulls from GHCR when deploying.

---

## Common Container Use Cases in HireFlow

| Component | Why Containerized |
|-----------|------------------|
| Node.js Backend API | Consistent Node version across all environments |
| React Frontend | Nginx + built static files in one portable unit |
| Database migrations | Run once as a Job container, then exit |
| CI build environment | Reproducible build tools, no host contamination |

---

## When NOT to Use Containers

Containers are not always the right choice:

| Scenario | Better Alternative |
|----------|------------------|
| Legacy Windows desktop apps | VM or bare metal |
| Apps requiring full OS customization | VM |
| Stateful databases (high I/O) | Managed DB service (RDS, Cloud SQL) |
| GPU-intensive workloads | Bare metal or specialized VMs |

For HireFlow, the stateless Node.js API and React frontend are ideal
container candidates. The database runs as a managed service outside
the cluster.

📄 File 2: docs/containers/hireflow-container-strategy.md
markdown# HireFlow Container Strategy
## Team 02 | Sprint #3 | Assignment 4.12

---

## Why HireFlow Uses Containers

The HireFlow recruitment platform has two core operational problems
that containers directly solve:

### Problem 1: Seasonal Surge Scaling
Campus recruitment season generates 8,000+ applications per day.
The platform must scale from 2 to 10 instances in under a minute.

**Container solution:**
- Pre-built images start new pods in ~5 seconds
- Kubernetes HPA pulls from registry and scales instantly
- No provisioning delay — image already exists in GHCR

### Problem 2: Form Version Traceability
After form updates, recruiters couldn't tell which form version
a candidate filled out.

**Container solution:**
- Every deployment uses an immutable image tagged with Git SHA
- The Git SHA maps to a specific form schema version
- Running `kubectl describe pod` reveals exact image tag deployed
- This tag traces back to the exact commit and form version

---

## HireFlow Container Architecture
```
GitHub Repository
       │
       │ git push (triggers CI)
       ▼
GitHub Actions Pipeline
       │
       ├── Build stage: npm install, npm test
       │
       ├── Docker build: creates image
       │   Tag: ghcr.io/team02/hireflow:sha-a3f91b2
       │
       └── Push to GHCR registry
               │
               ▼
       GitHub Container Registry (GHCR)
               │
               │ kubectl apply (CD stage)
               ▼
       Kubernetes Cluster
               │
       ┌───────┴───────┐
       │               │
   Pod 1           Pod 2 ... Pod 7 (HPA scaled)
   hireflow:       hireflow:
   sha-a3f91b2     sha-a3f91b2
   (same image,    (same image,
   guaranteed      no version
   consistency)    drift)
```

---

## Container vs Previous Deployment: Side by Side

### Before Containers (Manual Server Deployment)
```
Step 1:  SSH into server                    (2 mins)
Step 2:  git pull latest code               (1 min)
Step 3:  npm install                        (3 mins)
Step 4:  Set environment variables manually (5 mins)
Step 5:  pm2 restart app                    (1 min)
Step 6:  Verify manually                    (5 mins)
─────────────────────────────────────────────────
Total:   ~17 minutes | Manual | Error-prone
         No version history | No rollback
         Different servers = different configs
```

### After Containers (CI/CD + Kubernetes)
```
Step 1:  git push                           (developer action)
Step 2:  CI builds + tests image            (automated, ~3 mins)
Step 3:  Image pushed to GHCR              (automated)
Step 4:  kubectl rolling update            (automated, ~30 secs)
Step 5:  Health checks validate            (automated)
─────────────────────────────────────────────────
Total:   ~4 minutes | Fully automated
         Immutable image | One-command rollback
         All pods identical | Version tagged
```

---

## Delivery Benefits Summary

| Benefit | Impact on HireFlow |
|---------|-------------------|
| Consistency | Same image runs in dev, CI, staging, production |
| Speed | New pods scale in seconds during hiring surges |
| Traceability | Git SHA tag links every pod to exact code version |
| Rollback | `kubectl rollout undo` reverts to previous image instantly |
| Isolation | App dependencies don't conflict with host or other apps |
| Automation | CI/CD pipeline builds and ships without human intervention |