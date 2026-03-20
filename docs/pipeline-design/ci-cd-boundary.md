# CI vs CD Boundary — Explicit Definition
## HireFlow | Team 02 | Sprint #3 | Assignment 4.36

---

## The Boundary: Container Registry
```
CODE                    REGISTRY               CLUSTER
────────────────────    ──────────────────     ──────────────
      CI                    BOUNDARY                CD
────────────────────    ──────────────────     ──────────────
Checkout                                       Verify artifact
Install             →   Docker Hub         →   Update manifest
Test                    abhich98/hireflow       Apply to K8s
Lint                    :sha-a3f91b2            Verify rollout
Build               →   :v2.4.1            →
Tag + Push          →   :latest            →
```

The registry is the strict handoff point.
CI writes to the registry (pushes).
CD reads from the registry (pulls via Kubernetes).
Neither crosses into the other's territory.

---

## What CI Owns — Complete List
```
✅ CI OWNS:
  - Deciding whether code is safe to merge
  - Running all automated quality checks
  - Building the Docker image artifact
  - Tagging the image with version identifiers
  - Pushing the image to the registry
  - Reporting test results to developers

❌ CI DOES NOT OWN:
  - Deploying to any environment
  - Updating Kubernetes manifests
  - Communicating with the cluster
  - Monitoring running pods
  - Managing rollbacks
```

---

## What CD Owns — Complete List
```
✅ CD OWNS:
  - Deciding whether artifact is safe to deploy
  - Verifying the artifact exists in registry
  - Updating deployment manifests with new image tag
  - Applying manifests to the Kubernetes cluster
  - Monitoring rollout completion
  - Triggering rollback if deployment fails

❌ CD DOES NOT OWN:
  - Running tests
  - Building images
  - Making code quality decisions
  - Rebuilding source code
  - Publishing images to registry
```

---

## What Kubernetes Owns — Outside Both Pipelines
```
✅ KUBERNETES OWNS (independently of pipeline):
  - Scheduling pods onto appropriate nodes
  - Pulling images from registry (via kubelet + containerd)
  - Starting and stopping containers
  - Running liveness probes (restart unhealthy containers)
  - Running readiness probes (gate traffic to ready pods)
  - Maintaining replica count (ReplicaSet self-healing)
  - Auto-scaling pods based on CPU (HPA)
  - Load balancing traffic across pods (Service + kube-proxy)
  - Rescheduling pods from failed nodes

❌ KUBERNETES DOES NOT OWN:
  - Running tests
  - Building images
  - Making deployment decisions
  - Pushing images to registry
```

---

## Failure Impact by Stage
```
STAGE FAILS          IMPACT                    RECOVERY
───────────────────  ────────────────────────  ──────────────────
Stage 3 (Tests)      No image built            Fix code, push again
                     No deployment triggered   Pipeline auto-retries

Stage 5 (Build)      No image in registry      Fix Dockerfile, push again
                     No deployment triggered

Stage 6 (Push)       Image not in registry     Check registry credentials
                     CD cannot proceed         Re-run pipeline

Stage 9 (Deploy)     Cluster not updated       Fix manifest, re-run CD
                     Old version still running Old version keeps serving

Stage 10 (Verify)    Rollout not confirmed     kubectl rollout undo
                     Pipeline marked failed     Automatic rollback possible
                     Existing pods may be
                     unhealthy
```

---

## Conditions Required for CD to Run
```
CD ONLY runs when ALL of these are true:
  ✅ Trigger is a push to main branch (not a PR)
  ✅ CI Stage 1 (Checkout) passed
  ✅ CI Stage 2 (Install) passed
  ✅ CI Stage 3 (Tests) passed — zero failures
  ✅ CI Stage 4 (Lint) passed
  ✅ CI Stage 5 (Build) passed
  ✅ CI Stage 6 (Push) passed — image in registry

If ANY CI stage fails:
  CD does not run
  Existing deployment continues serving users
  No disruption to live traffic
  Developer receives failure notification
```