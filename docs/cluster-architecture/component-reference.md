# Kubernetes Component Reference — HireFlow
## Team 02 | Sprint #3 | Assignment 4.18

---

## Quick Reference Table

| Component | Location | Primary Responsibility | HireFlow Relevance |
|-----------|----------|----------------------|-------------------|
| API Server | Control Plane | Single entry point for all requests | Receives kubectl apply, validates manifests |
| etcd | Control Plane | Persistent storage of all cluster state | Stores deployment, configmap, HPA config |
| Scheduler | Control Plane | Assigns pods to nodes | Places hireflow pods across worker nodes |
| Controller Manager | Control Plane | Runs control loops, maintains desired state | ReplicaSet self-healing, HPA scaling |
| kubelet | Worker Node | Runs pods on the node, reports health | Starts hireflow containers, runs /health probes |
| kube-proxy | Worker Node | Network routing and load balancing | Routes traffic across 3-10 hireflow pods |
| containerd | Worker Node | Container runtime — pulls and runs images | Pulls abhich98/hireflow-backend:v2.4.1 |

---

## What Happens When Each Component Fails

### API Server fails
```
Impact:   kubectl commands stop working
          CI/CD pipeline cannot deploy
          No new pods can be scheduled
          EXISTING pods keep running (already on nodes)

Recovery: Control plane restarts API Server
          Cluster state preserved in etcd
          Existing workloads unaffected
```

### etcd fails
```
Impact:   Cluster loses ability to store/retrieve state
          New deployments fail
          Controller loops cannot function
          EXISTING pods keep running (kubelet is independent)

Recovery: Restore from etcd backup
          This is why etcd backups are critical in production
```

### Scheduler fails
```
Impact:   New pods stay in Pending state (no node assignment)
          Existing pods keep running
          HPA can request more pods but they won't be placed

Recovery: Scheduler restarts → processes pending pods
```

### Controller Manager fails
```
Impact:   Self-healing stops (crashed pods not replaced)
          HPA stops scaling
          Rolling updates cannot proceed
          Existing running pods unaffected

Recovery: Controller Manager restarts → reconciles state
```

### kubelet fails (on one node)
```
Impact:   Node marked NotReady after heartbeat timeout
          Pods on that node rescheduled to healthy nodes
          New pods not accepted by that node

For HireFlow:
  If Node 2 kubelet fails → Pod 2 rescheduled to Node 1 or 3
  HireFlow remains available throughout
```

### kube-proxy fails (on one node)
```
Impact:   Network routing breaks on that node
          Pods on that node unreachable via Service
          Traffic automatically stops going to those pods

For HireFlow:
  Candidates cannot reach pods on the affected node
  kube-proxy on other nodes continue working
  Fix: restart kube-proxy on affected node
```

---

## How HireFlow Uses Each Component
```
DEPLOYMENT FLOW:
git push → GitHub Actions → kubectl apply
                                   │
                                   ▼
                            API Server ← validates our YAML
                                   │
                                   ▼
                              etcd ← stores deployment spec
                                   │
                                   ▼
                     Controller Manager ← creates ReplicaSet + Pods
                                   │
                                   ▼
                           Scheduler ← assigns pods to nodes
                                   │
                                   ▼
                    kubelet (×3 nodes) ← starts containers
                                   │
                                   ▼
                      containerd (×3) ← pulls abhich98/hireflow-backend:v2.4.1
                                   │
                                   ▼
                       kube-proxy (×3) ← updates routing rules
                                   │
                                   ▼
                     HireFlow serving traffic ✅

SURGE HANDLING:
CPU > 60% → HPA Controller → API Server → etcd →
ReplicaSet Controller → new pods →
Scheduler → kubelet → containerd → kube-proxy
→ more pods serving ✅

SELF-HEALING:
Pod crash → kubelet reports → API Server → etcd →
ReplicaSet Controller → new pod →
Scheduler → kubelet → containerd → running ✅
```

---

## Common Interview/Scenario Questions

### Q: What happens if the control plane goes down?
```
A: Existing pods KEEP RUNNING.
   kubelet on each worker node continues managing its pods
   independently. Health probes still run. Containers restart
   if they crash (kubelet handles this locally).

   What STOPS working:
   - kubectl commands fail
   - New deployments cannot be made
   - HPA cannot scale
   - Self-healing cannot create NEW pods (only restart existing)

   This is why high-availability control planes run
   3 or 5 replicas across different availability zones.
```

### Q: What is etcd and why is it so important?
```
A: etcd is the only database in Kubernetes.
   It stores the desired state of every object.
   Without etcd, the cluster has no memory.

   If etcd data is lost:
   - All deployment configs are gone
   - All service definitions are gone
   - Cluster cannot reconcile state
   - Must restore from backup

   etcd backup is the most critical operational task
   for any Kubernetes cluster operator.
```

### Q: What is the difference between kubelet and kube-proxy?
```
A: kubelet manages the lifecycle of containers on a node.
   It's responsible for RUNNING pods.

   kube-proxy manages the NETWORK rules on a node.
   It's responsible for ROUTING traffic to pods.

   kubelet: "Start this container, check its health"
   kube-proxy: "Route traffic from this Service to these pods"

   Both run on every worker node but do completely different jobs.
```