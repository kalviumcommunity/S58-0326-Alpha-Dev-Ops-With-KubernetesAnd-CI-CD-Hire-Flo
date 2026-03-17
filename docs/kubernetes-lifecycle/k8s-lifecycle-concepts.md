# Kubernetes Application Lifecycle & Deployment Mechanics
## HireFlow | Team 02 | Sprint #3 | Assignment 4.4

---

## The Big Picture — Full Application Lifecycle

When HireFlow is deployed to Kubernetes, every deployment goes
through a well-defined, automated lifecycle:
```
Developer runs: kubectl apply -f k8s/deployment.yaml
                        │
                        ▼
        ┌───────────────────────────────┐
        │     Deployment Created        │
        │   (desired state declared)    │
        └───────────────┬───────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │      ReplicaSet Created       │
        │  (ensures N pods always run)  │
        └───────────────┬───────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │        Pods Created           │
        │   (3 pods for HireFlow API)   │
        └───────────────┬───────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │   Pods Scheduled on Nodes     │
        │  (Scheduler picks best node)  │
        └───────────────┬───────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │      Containers Start         │
        │  (Docker image pulled, app    │
        │   process launches as PID 1)  │
        └───────────────┬───────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │     Health Checks Pass        │
        │  (Liveness + Readiness probes │
        │   confirm app is working)     │
        └───────────────┬───────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │   Application Available ✅    │
        │  (Traffic routed to pods via  │
        │   Kubernetes Service)         │
        └───────────────────────────────┘
```

Kubernetes continuously watches every step and corrects any
deviation from the desired state automatically.

---

## Step 1: Pod Creation & Scheduling

### What is a Pod?

A Pod is the smallest deployable unit in Kubernetes.
It wraps one or more containers and shares:
- Network namespace (same IP address)
- Storage volumes
- Lifecycle (start/stop together)

For HireFlow, each pod runs one container:
`abhich98/hireflow-backend:v2.4.1`

### What Happens When You Apply a Deployment
```
kubectl apply -f k8s/deployment.yaml
        │
        ▼
API Server receives the request
        │
        ▼
Deployment Controller creates a ReplicaSet
        │
        ▼
ReplicaSet Controller creates Pod objects
        │
        ▼
Scheduler assigns each Pod to a Node
(considers: CPU available, memory available,
 node affinity rules, taints/tolerations)
        │
        ▼
kubelet on that Node pulls the image
        │
        ▼
Container runtime (containerd) starts the container
        │
        ▼
Pod status: Running
```

### Key Rule
You NEVER create pods directly in production.
Always use a Deployment → it manages pods through ReplicaSets.
```
❌ Wrong:  kubectl run hireflow --image=abhich98/hireflow-backend:v2.4.1
✅ Correct: kubectl apply -f k8s/deployment.yaml
```

---

## Step 2: ReplicaSets — The Self-Healing Mechanism

A ReplicaSet ensures the DESIRED number of pods are ALWAYS running.

### HireFlow ReplicaSet Behavior
```
Desired state: replicas: 3
Current state: 3 pods running ✅

Scenario 1: Pod crashes
  Before: Pod 1 ✅  Pod 2 ✅  Pod 3 ✅
  Event:  Pod 3 crashes ❌
  After:  Pod 1 ✅  Pod 2 ✅  Pod 4 ✅ (new pod created automatically)
  Time:   ~10 seconds

Scenario 2: Node failure
  Before: Node A (Pod 1, Pod 2)  Node B (Pod 3)
  Event:  Node A goes offline ❌
  After:  Node B (Pod 3)  Node C (Pod 1*, Pod 2*)  ← rescheduled
  Time:   ~30-60 seconds

Scenario 3: Hiring surge — scale up
  Before: replicas: 3
  Event:  HPA triggers scale up to 7
  After:  7 pods running ✅
  Time:   ~10 seconds per new pod

Scenario 4: Scale down after surge
  Before: replicas: 7
  Event:  HPA triggers scale down to 2
  After:  2 pods running ✅ (5 pods gracefully terminated)
```

### ReplicaSet Maintains Desired State
```
DESIRED STATE          CURRENT STATE          ACTION
─────────────          ─────────────          ──────
replicas: 3        →   2 pods running    →    Create 1 pod
replicas: 3        →   4 pods running    →    Terminate 1 pod
replicas: 3        →   3 pods running    →    Nothing (balanced)
```

---

## Step 3: Rolling Updates — Zero Downtime Deployments

When HireFlow form version updates from v2.3.0 to v2.4.1,
Kubernetes performs a rolling update:

### Rolling Update Flow
```
BEFORE UPDATE:
Pod 1 [v2.3.0] ✅   Pod 2 [v2.3.0] ✅   Pod 3 [v2.3.0] ✅
All serving traffic

STEP 1: Start new pod with v2.4.1
Pod 1 [v2.3.0] ✅   Pod 2 [v2.3.0] ✅   Pod 3 [v2.3.0] ✅
Pod 4 [v2.4.1] ⏳ (Starting...)

STEP 2: New pod passes readiness probe → receives traffic
Pod 1 [v2.3.0] ✅   Pod 2 [v2.3.0] ✅   Pod 3 [v2.3.0] ✅
Pod 4 [v2.4.1] ✅

STEP 3: Terminate one old pod
Pod 1 [v2.3.0] ✅   Pod 2 [v2.3.0] ✅
Pod 4 [v2.4.1] ✅

STEP 4: Start next new pod
Pod 1 [v2.3.0] ✅   Pod 2 [v2.3.0] ✅
Pod 4 [v2.4.1] ✅   Pod 5 [v2.4.1] ⏳

STEP 5: Repeat until all pods run v2.4.1
Pod 4 [v2.4.1] ✅   Pod 5 [v2.4.1] ✅   Pod 6 [v2.4.1] ✅

AFTER UPDATE:
All 3 pods running v2.4.1 ✅
Zero downtime — candidates never saw a gap in service
```

### Rollout Configuration
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1   # Max pods that can be down during update
    maxSurge: 1         # Max extra pods during update
```

### Rollout Outcomes
```
SUCCESS:  All new pods healthy → rollout complete
PAUSE:    Manual intervention needed (kubectl rollout pause)
FAILURE:  New pods never become healthy → rollout stuck

Check status:
kubectl rollout status deployment/hireflow -n recruitment

Rollback if needed:
kubectl rollout undo deployment/hireflow -n recruitment
```

---

## Step 4: Health Probes

Kubernetes uses probes to determine pod health.
Wrong probes = one of the most common causes of broken deployments.

### Three Types of Probes
```
LIVENESS PROBE
"Is the container alive?"
  → FAILS: container is RESTARTED
  → Use for: detecting deadlocks, hung processes

READINESS PROBE
"Can this pod receive traffic?"
  → FAILS: pod REMOVED from load balancer
           (traffic stops going to this pod)
  → Use for: app startup, temporary unavailability

STARTUP PROBE
"Has the app finished starting?"
  → FAILS: container is RESTARTED
  → Use for: slow-starting applications
  → Prevents liveness from killing pod during startup
```

### HireFlow Probe Configuration
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 10   # Wait 10s before first check
  periodSeconds: 30         # Check every 30 seconds
  timeoutSeconds: 3         # Fail if no response in 3s
  failureThreshold: 3       # Restart after 3 consecutive failures

readinessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 5    # Check sooner than liveness
  periodSeconds: 10         # Check more frequently
  timeoutSeconds: 3
  failureThreshold: 3       # Remove from LB after 3 failures
```

### Why This Matters for HireFlow
```
SCENARIO: New pod starts during rolling update
  t=0s:  Container starts, Node.js loading
  t=3s:  Readiness probe fires → app not ready yet → FAIL
         Pod NOT added to load balancer (correct behavior)
  t=8s:  App fully loaded, /health returns 200
  t=10s: Readiness probe fires → PASS
         Pod added to load balancer ✅ (now receives traffic)

WITHOUT readiness probe:
  t=0s:  Container starts
  t=1s:  Pod immediately added to load balancer
  t=2s:  Candidates hit pod → "Connection refused" ❌
  Result: Downtime during deployments
```

---

## Step 5: Resource Requests and Limits

Every HireFlow pod declares resource requirements:
```yaml
resources:
  requests:
    memory: "128Mi"   # Minimum guaranteed memory
    cpu: "100m"       # 0.1 CPU core guaranteed
  limits:
    memory: "256Mi"   # Maximum allowed memory
    cpu: "500m"       # Maximum 0.5 CPU core
```

### How Resources Affect Pod Behavior
```
REQUESTS (affects scheduling):
  Scheduler only places pod on nodes with enough available resources
  If no node has 128Mi free → pod stays Pending

LIMITS (affects runtime):
  CPU limit exceeded → pod is THROTTLED (slowed down, not killed)
  Memory limit exceeded → pod is OOMKilled (immediately terminated)

DURING HIRING SURGE:
  Normal: 3 pods × 128Mi = 384Mi total memory needed
  Surge:  7 pods × 128Mi = 896Mi total memory needed
  If cluster has < 896Mi available → some pods stay Pending
  Fix: either increase node size or reduce memory requests
```

### Resource States
```
Requests too HIGH → pod stuck in Pending
                    "Insufficient memory" in pod events

Limits too LOW → pod keeps OOMKilled
                 Memory usage spikes during surge
                 Pod killed → restarts → killed again → CrashLoopBackOff

Balanced correctly → pods schedule and run stably ✅
```

---

## Step 6: Pod States & Failure Diagnosis

Understanding pod states is the foundation of Kubernetes debugging.
```
POD STATE          MEANING                    COMMON CAUSE
──────────────     ──────────────────────     ──────────────────────────
Pending            Not yet scheduled          Insufficient resources,
                                              no matching node

ContainerCreating  Image being pulled         First deployment,
                                              slow registry pull

Running            Container executing        Normal state ✅

CrashLoopBackOff   App keeps crashing         App startup error,
                   K8s keeps restarting       missing env var,
                                              wrong CMD in Dockerfile

ImagePullBackOff   Image cannot be pulled     Wrong image tag,
                                              registry auth failed,
                                              image doesn't exist

OOMKilled          Memory limit exceeded      Memory leak,
                                              limit set too low,
                                              surge without HPA

Terminating        Pod shutting down          Scale down, rolling update,
                                              node drain

Evicted            Removed from node          Node ran out of disk/memory
```

### Debugging Flow
```
kubectl get pods -n recruitment
        │
        ├── Pending?
        │   kubectl describe pod <name> → check Events section
        │   Look for: "Insufficient memory" or "Unschedulable"
        │
        ├── CrashLoopBackOff?
        │   kubectl logs <pod-name> → check application error
        │   kubectl logs <pod-name> --previous → previous crash logs
        │
        ├── ImagePullBackOff?
        │   kubectl describe pod <name> → check image name/tag
        │   Verify: docker pull abhich98/hireflow-backend:v2.4.1
        │
        └── OOMKilled?
            kubectl describe pod <name> → check "Last State: OOMKilled"
            Fix: increase memory limit in deployment.yaml
```

---

## Step 7: Self-Healing in Action

Kubernetes automatically responds to failures
without any manual intervention:
```
FAILURE TYPE           K8S RESPONSE              TIME TO RECOVER
────────────────       ──────────────────────    ───────────────
Pod crash              Restart container         ~5-10 seconds
App deadlock           Liveness probe fails      ~90 seconds
                       → container restarted      (3×30s interval)
Node failure           Reschedule pods           ~30-60 seconds
                       to healthy nodes
Traffic spike          HPA scales up pods        ~30-60 seconds
Traffic drop           HPA scales down pods      ~5 minutes
Bad deployment         Rollout pauses/fails      Immediate detection
                       → manual rollback
```

### Important Limitation
```
Kubernetes guarantees DESIRED STATE — not APPLICATION CORRECTNESS.

Example:
  If server.js has a bug that crashes on every request:
  → Pod crashes ❌
  → K8s restarts it ✅
  → Pod crashes again ❌
  → K8s restarts it ✅
  → CrashLoopBackOff (K8s backs off restart frequency)

K8s did its job — it kept trying.
But it cannot fix your application code.
The fix must come from the developer.
```