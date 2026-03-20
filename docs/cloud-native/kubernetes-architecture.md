# Kubernetes & Cloud-Native Architecture — HireFlow
## Team 02 | Sprint #3 | Assignment 4.17

---

## Why Kubernetes for HireFlow?

HireFlow has two core operational problems that traditional
server deployments cannot solve:

### Problem 1: Seasonal Hiring Surges
```
Campus recruitment season: 8,000+ applications per day
Holiday hiring period:     3,000+ applications per day
Normal traffic:            200 applications per day

Ratio: 40x spike in traffic during peak periods

Traditional approach:
  - Manually provision servers before surge
  - Servers sit idle 90% of the year (wasted cost)
  - Human error in manual scaling → downtime

Kubernetes approach:
  - HPA automatically scales from 2 to 10 pods
  - Scales up when CPU hits 60% (proactive)
  - Scales down when surge ends (cost efficient)
  - Zero manual intervention required
```

### Problem 2: Form Version Traceability
```
Traditional approach:
  - Multiple servers running different code versions
  - No way to know which server a candidate hit
  - Recruiters cannot trace which form version was shown
  - Manual deployments cause version drift

Kubernetes approach:
  - All pods run identical immutable image
  - Image tag (v2.4.1) maps to exact form schema
  - Rolling updates guarantee consistency
  - kubectl describe pod → exact image version visible
```

---

## What Kubernetes Is Responsible For
```
┌─────────────────────────────────────────────────────────┐
│              KUBERNETES RESPONSIBILITIES                 │
│                                                         │
│  ┌─────────────────────────────────────────────────┐    │
│  │ SCHEDULING                                      │    │
│  │ → Decides which node runs which pod             │    │
│  │ → Considers: CPU, memory, affinity rules        │    │
│  └─────────────────────────────────────────────────┘    │
│                                                         │
│  ┌─────────────────────────────────────────────────┐    │
│  │ SELF-HEALING                                    │    │
│  │ → Restarts crashed containers                   │    │
│  │ → Reschedules pods from failed nodes            │    │
│  │ → Replaces unhealthy pods automatically         │    │
│  └─────────────────────────────────────────────────┘    │
│                                                         │
│  ┌─────────────────────────────────────────────────┐    │
│  │ SCALING                                         │    │
│  │ → HPA increases/decreases replica count         │    │
│  │ → Based on CPU, memory, or custom metrics       │    │
│  └─────────────────────────────────────────────────┘    │
│                                                         │
│  ┌─────────────────────────────────────────────────┐    │
│  │ ROLLING UPDATES                                 │    │
│  │ → Deploys new image version pod by pod          │    │
│  │ → Maintains availability throughout             │    │
│  │ → Rolls back automatically on failure           │    │
│  └─────────────────────────────────────────────────┘    │
│                                                         │
│  ┌─────────────────────────────────────────────────┐    │
│  │ SERVICE DISCOVERY                               │    │
│  │ → Stable DNS names for services                 │    │
│  │ → Load balancing across healthy pods            │    │
│  │ → Routes traffic only to ready pods             │    │
│  └─────────────────────────────────────────────────┘    │
│                                                         │
│  ┌─────────────────────────────────────────────────┐    │
│  │ CONFIG & SECRET MANAGEMENT                      │    │
│  │ → Injects ConfigMaps as environment variables   │    │
│  │ → Mounts Secrets securely                       │    │
│  │ → Config changes without image rebuild          │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

---

## What Developers Are Still Responsible For
```
┌─────────────────────────────────────────────────────────┐
│              DEVELOPER RESPONSIBILITIES                  │
│                                                         │
│  ┌─────────────────────────────────────────────────┐    │
│  │ APPLICATION CODE                                │    │
│  │ → Writing correct business logic               │    │
│  │ → Handling errors gracefully                    │    │
│  │ → K8s restarts crashes but can't fix bugs       │    │
│  └─────────────────────────────────────────────────┘    │
│                                                         │
│  ┌─────────────────────────────────────────────────┐    │
│  │ HEALTH CHECK ENDPOINTS                          │    │
│  │ → Implementing /health that returns 200         │    │
│  │ → K8s uses this for liveness/readiness probes   │    │
│  │ → Bad /health = broken probe = broken deploy    │    │
│  └─────────────────────────────────────────────────┘    │
│                                                         │
│  ┌─────────────────────────────────────────────────┐    │
│  │ DOCKERFILE                                      │    │
│  │ → Writing efficient, correct Dockerfiles        │    │
│  │ → K8s pulls images but can't fix bad images     │    │
│  └─────────────────────────────────────────────────┘    │
│                                                         │
│  ┌─────────────────────────────────────────────────┐    │
│  │ KUBERNETES MANIFESTS                            │    │
│  │ → Writing deployment.yaml, service.yaml         │    │
│  │ → Declaring correct resource limits             │    │
│  │ → Configuring probes with right thresholds      │    │
│  └─────────────────────────────────────────────────┘    │
│                                                         │
│  ┌─────────────────────────────────────────────────┐    │
│  │ OBSERVABILITY                                   │    │
│  │ → Application logs (what to log, log format)    │    │
│  │ → Meaningful metrics and alerts                 │    │
│  │ → K8s shows pod state, not app business state   │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

---

## Cloud-Native Architecture for HireFlow
```
INTERNET
    │
    │ HTTPS requests from candidates
    ▼
┌──────────────────────────────────────────────────────┐
│                  KUBERNETES CLUSTER                  │
│                                                      │
│  ┌────────────────────────────────────────────────┐  │
│  │              INGRESS CONTROLLER                │  │
│  │   Routes external traffic to internal services │  │
│  └─────────────────────┬──────────────────────────┘  │
│                        │                             │
│                        ▼                             │
│  ┌────────────────────────────────────────────────┐  │
│  │           HIREFLOW SERVICE (ClusterIP)         │  │
│  │   Stable DNS: hireflow-service.recruitment     │  │
│  │   Load balances across healthy pods            │  │
│  └──────────┬──────────────────┬──────────────────┘  │
│             │                  │                     │
│    ┌────────▼──────┐  ┌───────▼────────┐            │
│    │     Pod 1     │  │     Pod 2      │  ...Pod N  │
│    │ abhich98/     │  │ abhich98/      │            │
│    │ hireflow:     │  │ hireflow:      │            │
│    │ v2.4.1        │  │ v2.4.1         │            │
│    │ ───────────── │  │ ────────────── │            │
│    │ /health ✅    │  │ /health ✅     │            │
│    └───────────────┘  └────────────────┘            │
│                                                      │
│  ┌────────────────────────────────────────────────┐  │
│  │              HORIZONTAL POD AUTOSCALER         │  │
│  │   CPU > 60% → scale up   CPU < 30% → scale down│  │
│  │   Min: 2 pods            Max: 10 pods          │  │
│  └────────────────────────────────────────────────┘  │
│                                                      │
│  ┌────────────────────────────────────────────────┐  │
│  │                  CONFIGMAP                     │  │
│  │   FORM_VERSION=v2.4.1                          │  │
│  │   Injected into all pods as env var            │  │
│  └────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────┘
         │
         │ kubectl apply (CI/CD pipeline)
         │
┌────────▼─────────────────────────────────────────────┐
│              GITHUB ACTIONS CI/CD                    │
│  git push → build → test → push image → deploy       │
└──────────────────────────────────────────────────────┘
         │
         │ docker push
         ▼
┌─────────────────────────────────────────────────────┐
│           DOCKER HUB REGISTRY                       │
│   abhich98/hireflow-backend:v2.4.1                  │
│   abhich98/hireflow-backend:sha-a3f91b2             │
└─────────────────────────────────────────────────────┘
```

---

## Cloud-Native Principles Applied to HireFlow

| Principle | How HireFlow Implements It |
|-----------|--------------------------|
| **Containerization** | Docker image packages app + runtime + deps |
| **Declarative config** | YAML manifests declare desired state |
| **Immutable infrastructure** | Images never modified — rebuilt on change |
| **Dynamic scaling** | HPA scales 2-10 pods based on CPU |
| **Self-healing** | K8s restarts failed pods automatically |
| **Config externalization** | FORM_VERSION in ConfigMap, not in image |
| **Health observability** | /health endpoint for liveness/readiness |
| **Zero-downtime deploys** | Rolling update strategy |

---

## Before vs After Kubernetes
```
BEFORE KUBERNETES               AFTER KUBERNETES
──────────────────────────      ──────────────────────────────
Manual server provisioning  →   Declarative YAML manifests
SSH into servers to deploy  →   kubectl apply or CI/CD pipeline
Manual scaling during surge →   HPA auto-scales pods
Downtime during updates     →   Rolling updates, zero downtime
Version drift across servers→   All pods run identical image
No form version tracking    →   Image tag = form schema version
Manual restart on crash     →   K8s self-healing (automatic)
Config hardcoded in code    →   ConfigMap injection
```