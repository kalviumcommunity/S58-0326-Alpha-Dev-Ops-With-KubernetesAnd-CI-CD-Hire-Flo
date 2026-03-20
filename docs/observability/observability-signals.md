# Observability Signals Reference — HireFlow
## Team 02 | Sprint #3 | Assignment 4.43

---

## When to Use Each Signal

| Situation | Use | Why |
|-----------|-----|-----|
| System is slow — how slow? | Metrics | P99 latency gives quantified answer |
| System is slow — which part? | Traces | Shows exact span durations |
| Pod crashed — what error? | Logs | Stack trace and error message |
| Pod crashed — how often? | Metrics | Restart count over time |
| Specific request failed — why? | Logs | Event sequence for that request |
| Specific request slow — where? | Traces | Span breakdown per service |
| Campus surge — are we scaling? | Metrics | Pod count, CPU utilization |
| Deployment failed — what broke? | Logs | First error after deploy |
| Intermittent failures — pattern? | Metrics | Error rate trend over time |
| Two services correlated issue | Traces | Request path across both |

---

## Signal Characteristics
```
METRICS                    LOGS                      TRACES
────────────────────────   ───────────────────────   ────────────────────────
Numeric values             Text events               Request journey maps
Aggregated over time       Individual occurrences    Per-request breakdown
Low storage cost           Medium storage cost       High storage cost
Always on (polling)        Generated on events       Generated per request
Great for alerting         Great for debugging       Great for performance
Shows trends               Shows specifics           Shows relationships
Answered: What/When        Answers: What happened    Answers: Where/How long
Example tool: Prometheus   Example tool: Loki        Example tool: Jaeger
```

---

## HireFlow Observability Gaps Without Each Pillar

### Without Metrics
```
❌ No alerts when error rate rises
❌ No visibility into HPA scaling behavior
❌ Cannot quantify whether performance improved after a fix
❌ No dashboard showing platform health during hiring surge
❌ Cannot set SLOs (Service Level Objectives)
   e.g., "99.9% of form submissions complete in under 500ms"
```

### Without Logs
```
❌ Cannot diagnose CrashLoopBackOff — don't know the error
❌ Cannot answer recruiter questions about specific submissions
❌ Cannot trace which form version a specific candidate saw
❌ Cannot find the first error after a bad deployment
❌ Cannot debug issues that only happen on specific pods
```

### Without Traces
```
❌ Cannot identify which service in the chain caused slowness
❌ Cannot distinguish: is the slowness in our code or the DB?
❌ Cannot debug intermittent slowness affecting 1% of requests
❌ Cannot prove a fix worked by showing span duration improved
❌ Cannot identify N+1 query problems or connection pool exhaustion
```

---

## Kubernetes Observability Commands Available Now
```bash
# LOGS — available with kubectl today
kubectl logs pod-name -n recruitment
kubectl logs pod-name -n recruitment --previous   # last crashed instance
kubectl logs -n recruitment -l app=hireflow       # all pods
kubectl logs -f pod-name -n recruitment           # follow in real time
kubectl logs --tail=100 pod-name -n recruitment   # last 100 lines

# METRICS — basic signals from kubectl
kubectl top pods -n recruitment      # CPU + memory per pod (needs metrics-server)
kubectl top nodes                    # CPU + memory per node
kubectl get hpa -n recruitment       # HPA scaling decisions

# POD HEALTH SIGNALS
kubectl describe pod pod-name -n recruitment  # Events + probe status
kubectl get events -n recruitment            # All cluster events
kubectl get events -n recruitment --sort-by='.lastTimestamp'
```