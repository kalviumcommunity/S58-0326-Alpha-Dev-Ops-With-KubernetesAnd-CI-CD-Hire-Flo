# Kubernetes Cluster Architecture & Control Plane
## HireFlow | Team 02 | Sprint #3 | Assignment 4.18

---

## What is a Kubernetes Cluster?

A Kubernetes cluster is a group of machines (nodes) that work
together to run containerized applications reliably at scale.

For HireFlow, the cluster ensures:
- 3 pods always running (ReplicaSet)
- Auto-scaling during campus hiring surges (HPA)
- Zero-downtime form version updates (rolling updates)
- Self-healing when pods crash (controller manager)

A cluster has two types of machines:

┌─────────────────────────────────────────────────────────────┐
│                    KUBERNETES CLUSTER                       │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                  CONTROL PLANE                       │   │
│  │         (The brain — manages everything)             │   │
│  │                                                      │   │
│  │  ┌────────────┐  ┌──────────┐  ┌─────────────────┐  │   │
│  │  │ API Server │  │  etcd    │  │   Scheduler     │  │   │
│  │  │            │  │          │  │                 │  │   │
│  │  │ Front door │  │ Database │  │ Pod placement   │  │   │
│  │  │ for all    │  │ of all   │  │ decision maker  │  │   │
│  │  │ requests   │  │ cluster  │  │                 │  │   │
│  │  │            │  │ state    │  │                 │  │   │
│  │  └────────────┘  └──────────┘  └─────────────────┘  │   │
│  │                                                      │   │
│  │  ┌──────────────────────────────────────────────┐   │   │
│  │  │         Controller Manager                   │   │   │
│  │  │  Watches state, triggers corrections         │   │   │
│  │  └──────────────────────────────────────────────┘   │   │
│  └──────────────────────────────────────────────────────┘   │
│                           │                                 │
│              ┌────────────┼────────────┐                    │
│              │            │            │                    │
│   ┌──────────▼──┐  ┌──────▼──────┐  ┌─▼────────────┐       │
│   │  WORKER     │  │  WORKER     │  │  WORKER      │       │
│   │  NODE 1     │  │  NODE 2     │  │  NODE 3      │       │
│   │             │  │             │  │              │       │
│   │ Pod 1 ✅    │  │ Pod 2 ✅    │  │ Pod 3 ✅     │       │
│   │ kubelet     │  │ kubelet     │  │ kubelet      │       │
│   │ kube-proxy  │  │ kube-proxy  │  │ kube-proxy   │       │
│   │ containerd  │  │ containerd  │  │ containerd   │       │
│   └─────────────┘  └─────────────┘  └──────────────┘       │
└─────────────────────────────────────────────────────────────┘

---

## The Control Plane — The Brain of the Cluster

The control plane makes all global decisions about the cluster.
It does NOT run your application workloads.
It manages, schedules, and monitors everything.

### Component 1: API Server (kube-apiserver)WHAT IT IS:
The single entry point for ALL cluster operations.
Every kubectl command, every CI/CD pipeline action,
every internal component — all go through the API Server.WHAT IT DOES:

Receives and validates all API requests
Authenticates and authorizes requests
Reads/writes cluster state to etcd
Notifies other components of state changes
HOW IT RELATES TO HIREFLOW:
When our CI/CD pipeline runs:
kubectl apply -f k8s/deployment.yamlThis request goes to the API Server.
API Server validates the YAML → writes to etcd →
notifies Scheduler and Controller Manager.ANALOGY:
API Server = Reception desk of a large company.
Every request must go through reception.
Reception validates your ID, logs your visit,
and directs you to the right department.

### Component 2: etcdWHAT IT IS:
A distributed key-value database.
The ONLY persistent storage in Kubernetes.
Everything Kubernetes knows is stored here.WHAT IT STORES:

All cluster configuration
All resource definitions (Deployments, Services, Pods)
Current state of every object in the cluster
Node registrations and health status
HOW IT RELATES TO HIREFLOW:
When we apply our deployment.yaml:
etcd stores:
- hireflow deployment: replicas=3, image=abhich98/hireflow-backend:v2.4.1
- hireflow configmap: FORM_VERSION=v2.4.1
- hireflow service: port 80 → 3000
- hireflow hpa: min=2, max=10, cpu=60%If the control plane restarts → reads etcd → restores state.
etcd is the source of truth for the entire cluster.CRITICAL RULE:
NEVER lose etcd data.
If etcd is corrupted → cluster loses all state.
Always back up etcd in production.ANALOGY:
etcd = The company's central database and filing system.
Every decision, every record, every state — stored here.
If this burns down, the company loses its memory.

### Component 3: Scheduler (kube-scheduler)WHAT IT IS:
The component that decides WHICH node runs WHICH pod.
It watches for unscheduled pods and assigns them to nodes.WHAT IT CONSIDERS:

Available CPU and memory on each node
Resource requests declared in pod spec
Node affinity and anti-affinity rules
Taints and tolerations
Pod topology spread constraints
HOW IT RELATES TO HIREFLOW:During campus hiring surge:
HPA requests 7 pods (up from 3).
4 new pods created → status: Pending (no node assigned yet)Scheduler sees 4 unscheduled pods:
Pod 4: needs 100m CPU, 128Mi memory
→ Node 1 has 400m free, 512Mi free → ASSIGNED ✅
Pod 5: needs 100m CPU, 128Mi memory
→ Node 2 has 350m free, 400Mi free → ASSIGNED ✅
Pod 6: needs 100m CPU, 128Mi memory
→ Node 3 has 300m free, 256Mi free → ASSIGNED ✅
Pod 7: needs 100m CPU, 128Mi memory
→ All nodes full → stays PENDING ❌
→ Fix: add more nodes or reduce resource requestsANALOGY:
Scheduler = HR department assigning employees to offices.
Checks which offices have space, which employees need what,
and makes the optimal assignment decision.

### Component 4: Controller Manager (kube-controller-manager)WHAT IT IS:
Runs multiple control loops that continuously watch cluster
state and take corrective action to match desired state.KEY CONTROLLERS INSIDE IT:
ReplicaSet Controller:
Watches: "hireflow should have 3 pods"
Sees: only 2 pods running (one crashed)
Action: creates 1 new pod immediatelyDeployment Controller:
Watches: deployment update triggered
Action: manages rolling update process
creates new ReplicaSet for new version
scales down old ReplicaSet graduallyNode Controller:
Watches: node health status via heartbeats
Sees: Node 2 stopped sending heartbeats
Action: marks node as NotReady
reschedules pods from Node 2 to other nodesHPA Controller:
Watches: CPU metrics from pods
Sees: average CPU > 60%
Action: increases replicas from 3 to 7HOW IT RELATES TO HIREFLOW:
The Controller Manager is what makes self-healing work.
When a HireFlow pod crashes:

ReplicaSet Controller detects: current=2, desired=3
Creates new pod spec
API Server saves to etcd
Scheduler assigns to a node
kubelet on that node starts the container
Pod replaced in ~10 seconds. Zero manual intervention.
ANALOGY:
Controller Manager = Multiple department managers.
Each manager watches their domain and fixes problems.
HR manager notices understaffing → hires new person.
Facilities manager notices broken equipment → calls repair.

---

## Worker Nodes — Where Applications Actually Run

Worker nodes are the machines that run your application pods.
The control plane tells workers WHAT to run.
Workers do the actual running.

### Component 1: kubeletWHAT IT IS:
The agent that runs on EVERY worker node.
It's the direct communication link between the
control plane and the node.WHAT IT DOES:

Receives pod specs from the API Server
Tells the container runtime to start/stop containers
Reports pod and node health back to control plane
Runs health check probes (liveness, readiness)
Manages container lifecycle on the node
HOW IT RELATES TO HIREFLOW:
When Scheduler assigns Pod 1 to Node 1:API Server → notifies kubelet on Node 1
kubelet reads pod spec:
image: abhich98/hireflow-backend:v2.4.1
env: FORM_VERSION=v2.4.1 (from ConfigMap)
ports: 3000
livenessProbe: GET /health every 30skubelet → tells containerd: pull and run this image
containerd → pulls from Docker Hub → starts container
kubelet → runs /health probe every 30s
kubelet → reports status back to API Server → stored in etcdIf /health fails 3 times:
kubelet → tells containerd: restart this container
Pod restarted within seconds.ANALOGY:
kubelet = Team supervisor on the factory floor.
Receives instructions from management (control plane).
Directly supervises workers (containers).
Reports back on productivity and problems.

### Component 2: kube-proxyWHAT IT IS:
Network proxy running on every worker node.
Manages network rules that allow pod communication
and implement Kubernetes Services.WHAT IT DOES:

Maintains network routing rules (iptables/ipvs)
Enables Service load balancing across pods
Allows pods on different nodes to communicate
Routes external traffic to correct pods
HOW IT RELATES TO HIREFLOW:
Our Service (hireflow-service) routes port 80 to pods on 3000.Without kube-proxy:
Request comes in → no routing rules → connection refusedWith kube-proxy:
Request to hireflow-service:80
→ kube-proxy routing rules activate
→ load balanced across Pod 1, Pod 2, Pod 3
→ request reaches correct pod on port 3000
→ response returned to clientDuring surge with 7 pods:
kube-proxy automatically includes all 7 pods in rotation.
No manual update needed.ANALOGY:
kube-proxy = Telephone switchboard operator.
Knows which extension (pod) to connect each call (request) to.
Keeps the directory updated as people (pods) join/leave.

### Component 3: Container Runtime (containerd)WHAT IT IS:
The software that actually runs containers on the node.
Kubernetes uses containerd (also used by Docker Desktop).WHAT IT DOES:

Pulls container images from registry (Docker Hub/GHCR)
Creates and starts containers from images
Stops and removes containers
Manages container storage and networking
HOW IT RELATES TO HIREFLOW:
kubelet says: "Run abhich98/hireflow-backend:v2.4.1"
containerd:
1. Checks if image cached locally
2. If not: pulls from Docker Hub
3. Creates container from image layers
4. Starts node server.js as PID 1
5. Reports container ID back to kubeletANALOGY:
containerd = The factory machines that do the actual work.
kubelet (supervisor) gives instructions.
containerd (machine) executes them.

---

## How Components Interact — Full Request Flow

### Flow 1: Deploying HireFlow for the First TimeDeveloper
│
│ kubectl apply -f k8s/deployment.yaml
▼
API Server
│ Validates YAML ✅
│ Writes to etcd ✅
▼
etcd
│ State saved: "hireflow deployment, replicas=3"
│ Notifies watchers
▼
Controller Manager (Deployment Controller)
│ Sees new Deployment
│ Creates ReplicaSet
▼
Controller Manager (ReplicaSet Controller)
│ Sees ReplicaSet needs 3 pods
│ Creates 3 Pod objects (status: Pending)
▼
API Server → etcd (3 pods saved as Pending)
│
▼
Scheduler
│ Sees 3 Pending pods
│ Evaluates all nodes
│ Assigns Pod1→Node1, Pod2→Node2, Pod3→Node3
▼
API Server → etcd (pods now have node assignments)
│
▼
kubelet on Node 1, Node 2, Node 3
│ Each kubelet sees its assigned pod
│ Tells containerd: pull and run the image
▼
containerd (on each node)
│ Pulls abhich98/hireflow-backend:v2.4.1
│ Starts container
▼
kubelet
│ Runs readiness probe → /health → 200 OK
│ Reports: Pod status = Running
▼
API Server → etcd (pods updated to Running)
│
▼
kube-proxy
│ Updates routing rules
│ Traffic now flows to all 3 podsAPPLICATION AVAILABLE ✅

### Flow 2: Pod Crashes — Self-HealingPod 2 crashes (Node.js process exits)
│
▼
kubelet on Node 2
│ Detects container exited
│ Reports to API Server: Pod 2 = Failed
▼
API Server → etcd (Pod 2 status = Failed)
│
▼
Controller Manager (ReplicaSet Controller)
│ Desired: 3 pods  Current: 2 pods
│ Creates new Pod object (Pod 4)
▼
Scheduler
│ Assigns Pod 4 → Node 2 (or best available node)
▼
kubelet on Node 2
│ Starts new container
│ Readiness probe passes
▼
3 pods running again ✅
Total time: ~10 seconds

### Flow 3: HireFlow Hiring Surge — HPA ScalingCampus recruitment season begins
│
▼
Metrics Server
│ Collects CPU from all hireflow pods
│ Average CPU = 75% (above 60% threshold)
▼
Controller Manager (HPA Controller)
│ Current replicas: 3
│ Calculates needed: ceil(3 × 75/60) = 4 pods
│ Updates Deployment: replicas = 4
▼
API Server → etcd (replicas updated to 4)
│
▼
ReplicaSet Controller
│ Creates 1 new pod
▼
Scheduler → assigns to node
▼
kubelet → containerd → container starts
▼
kube-proxy updates routing rules
▼
4 pods now serving traffic ✅(Repeat until CPU drops below threshold)

---

## Control Plane vs Worker Node — Responsibility SplitCONTROL PLANE                      WORKER NODES
─────────────────────────────      ──────────────────────────────
What to run (desired state)    →   Actually running the workload
Where to run it (scheduling)   →   Executing the schedule
Watching for failures          →   Reporting failures
Deciding on corrections        →   Applying corrections
Storing all cluster state      →   Storing nothing persistent
Managing the cluster           →   Running the applicationFor HireFlow:
Control plane decides:             Worker nodes execute:
"3 hireflow pods needed"    →      Running the containers
"Pod crashed, replace it"   →      Starting replacement
"Scale to 7 during surge"   →      Running 7 containers
"Roll out v2.4.1"           →      Stopping v2.3.0, starting v2.4.1
