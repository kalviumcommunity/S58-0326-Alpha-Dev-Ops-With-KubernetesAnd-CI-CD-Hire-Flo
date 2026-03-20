# Understanding Observability: Metrics, Logs, and Traces
## HireFlow | Team 02 | Sprint #3 | Assignment 4.43

---

## Observability vs Monitoring — Critical Distinction

These two terms are often confused. They are not the same.MONITORING                          OBSERVABILITY
──────────────────────────────      ──────────────────────────────
Answers KNOWN questions             Answers UNKNOWN questions
"Is CPU above 80%?"                 "Why did this specific request
"Are pods healthy?"                  fail for this specific user?"Tracks predefined metrics           Explores system behavior
Alert when threshold crossed        Diagnose problems never seen beforeExample:                            Example:
Alert: Pod CPU > 80%                Question: "Why is candidate
Action: Scale up                    APP-1042's form submission
taking 12 seconds but
APP-1041 takes 200ms?"Monitoring tells you SOMETHING      Observability tells you WHY
is wrong.                           it is wrong.

**Observability is the property of a system that allows you**
**to understand its internal state from its external outputs.**

An observable system answers questions you didn't know to ask
before a problem occurred.

---

## The Three Pillars of Observability┌─────────────────────────────────────────────────────────────┐
│                    OBSERVABILITY                            │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │   METRICS   │  │    LOGS     │  │       TRACES        │ │
│  │             │  │             │  │                     │ │
│  │ Numbers     │  │ Events      │  │ Request journeys    │ │
│  │ over time   │  │ as text     │  │ across services     │ │
│  │             │  │             │  │                     │ │
│  │ "What is    │  │ "What       │  │ "Where did this     │ │
│  │ happening?" │  │ happened?"  │  │ request go?"        │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
│                                                             │
│  Used together → complete picture of system health         │
│  Used alone    → incomplete, potentially misleading        │
└─────────────────────────────────────────────────────────────┘

---

## Pillar 1: Metrics

### What Metrics Are

Metrics are **numeric measurements collected at regular intervals**
over time. They represent the quantitative state of a system.FORMAT:
metric_name{labels} value timestampEXAMPLE:
http_requests_total{endpoint="/health", status="200"} 8472 1710823200
pod_cpu_usage{pod="hireflow-pod-1", namespace="recruitment"} 0.45 1710823200
form_submissions_total{version="v2.4.1"} 847 1710823200

### What Questions Metrics Answer"How many?"        → http_requests_total = 8,472 in last hour
"How much?"        → pod_memory_usage = 127MB per pod
"How fast?"        → request_duration_p99 = 340ms (99th percentile)
"How often?"       → pod_restart_count = 3 restarts in 1 hour
"How many pods?"   → kubernetes_running_pods = 7 (HPA scaled up)

### Metrics in HireFlow — Specific ExamplesMETRIC 1: form_submissions_per_minute
Value during normal traffic:     3-5 submissions/min
Value during campus hiring day:  85-120 submissions/minWhy it matters:
This metric triggers HPA scaling.
When submission rate spikes → CPU spikes → HPA adds pods.
Without this metric, the platform would slow down before
anyone noticed the surge was happening.METRIC 2: pod_cpu_utilization_percent
Normal: 15-25%
Surge:  65-80%
HPA threshold: 60%Why it matters:
When this metric crosses 60%, Kubernetes HPA automatically
scales from 2 pods to up to 10 pods.
This is the specific metric that solves HireFlow's
campus recruitment season problem.METRIC 3: http_request_duration_p99_milliseconds
Healthy: < 200ms
Degraded: 500ms - 2000ms
Critical: > 5000msWhy it matters:
If 99% of requests complete in 200ms but 1% take 8 seconds,
the average looks fine (210ms) but 1 in 100 candidates
experiences an 8-second wait. The P99 metric surfaces this
problem that the average hides.METRIC 4: kubernetes_pod_restart_count
Healthy: 0 restarts
Warning: 3+ restarts in 1 hour
Critical: CrashLoopBackOff (restarts with backoff)Why it matters:
A pod restarting 3 times in an hour indicates a recurring
crash. Without this metric, the team might not notice until
a candidate reports a form submission error.

### What Metrics Cannot Tell YouMETRICS CAN TELL YOU:
CPU is 85% → something is consuming resources
Error rate is 5% → 1 in 20 requests is failing
Pod restarted 3 times → something keeps crashingMETRICS CANNOT TELL YOU:
Which specific requests are failing (need Logs)
Why a specific candidate's submission took 8 seconds (need Traces)
What error message appeared before the crash (need Logs)
Which downstream service caused the slowdown (need Traces)Metrics give you WHAT and WHEN.
Logs and Traces give you WHY and WHERE.

---

## Pillar 2: Logs

### What Logs Are

Logs are **discrete, timestamped records of events** that occurred
inside an application or system. Each log entry describes something
that happened at a specific moment in time.FORMAT (structured JSON log):
{
"timestamp": "2026-03-19T06:58:52Z",
"level": "INFO",
"service": "hireflow-backend",
"pod": "hireflow-c6f989dbc-5pn8x",
"message": "Form submitted",
"application_id": "APP-1042",
"form_version": "v2.4.1",
"duration_ms": 142,
"candidate_id": "C-8891"
}

### What Questions Logs Answer"What happened?"   → Form submission failed with error: ECONNREFUSED
"When exactly?"    → At 2026-03-19T06:58:52.334Z
"For which user?"  → Candidate APP-1042, form version v2.4.1
"What error?"      → Cannot read properties of undefined (reading 'formId')
"Which pod?"       → hireflow-c6f989dbc-5pn8x on Node 1
"After what?"      → After database connection pool exhausted

### Logs in HireFlow — Specific ExamplesSCENARIO 1: Pod in CrashLoopBackOffCommand to get logs:
kubectl logs hireflow-pod-xyz -n recruitment
kubectl logs hireflow-pod-xyz -n recruitment --previousLog output:
[HireFlow] Server starting...
[HireFlow] Reading FORM_VERSION from environment...
[HireFlow] Error: Cannot read properties of undefined
(reading 'FORM_VERSION')
[HireFlow] Process exiting with code 1What the log tells us:
The ConfigMap reference is broken. FORM_VERSION is undefined
because the ConfigMap key name was misspelled in deployment.yaml.
The metrics only showed "pod restarted 3 times."
The log reveals the EXACT cause: missing environment variable.SCENARIO 2: Form version mismatch complaint from recruiterRecruiter says: "Candidate APP-1042 says they filled v2.4.1
but our system shows v2.3.0 for their submission"Log search:
kubectl logs -n recruitment --selector app=hireflow 
| grep "APP-1042"Log output:
{"timestamp":"2026-03-19T10:32:01Z",
"application_id":"APP-1042",
"form_version":"v2.3.0",
"pod":"hireflow-c6f989dbc-jz754",
"message":"Application submitted"}What the log tells us:
Pod jz754 was running an old image during the rolling update.
The rolling update was in progress when this submission happened.
One pod still ran v2.3.0 while two pods ran v2.4.1.
The load balancer sent this candidate to the old pod.SCENARIO 3: Slow submission during hiring surgeLog search for slow requests:
kubectl logs -n recruitment -l app=hireflow 
| grep "duration_ms" | awk -F'"duration_ms":' '{print $2}' 
| sort -n | tail -10Log output shows:
duration_ms: 8432  ← 8.4 seconds
duration_ms: 7891
duration_ms: 6234What the log tells us:
Specific requests took 8+ seconds. But logs alone cannot tell
us WHY — was it the database? Network? A downstream service?
This is where Traces become necessary.

### What Logs Cannot Tell YouLOGS CAN TELL YOU:
Exact error message and stack trace
Which specific request failed
What the application was doing at the time
Sequence of events leading to a failureLOGS CANNOT TELL YOU:
The overall trend (is error rate increasing?) → need Metrics
Which service in a chain caused the slowdown → need Traces
How this compares to normal behavior → need Metrics
The path of a request across 3 microservices → need TracesLogs give you WHAT happened at a specific moment.
Metrics give you trends. Traces give you request paths.

---

## Pillar 3: Traces

### What Traces Are

A trace is a **record of the complete journey of a single request**
as it flows through a system. In distributed systems with multiple
services, a single user request may touch 5-10 different services.
A trace shows exactly where time was spent at each step.TRACE STRUCTURE:Trace ID: abc-123-xyz
Total duration: 1,240ms├── Span 1: API Gateway
│   Duration: 12ms
│   Started: 10:32:01.000
│   Ended:   10:32:01.012
│
├── Span 2: HireFlow Backend
│   Duration: 1,180ms  ← most time here
│   Started: 10:32:01.012
│   Ended:   10:32:02.192
│   │
│   ├── Span 2a: Form validation
│   │   Duration: 8ms
│   │
│   ├── Span 2b: Database write
│   │   Duration: 1,145ms ← ROOT CAUSE: DB slow
│   │
│   └── Span 2c: ConfigMap read
│       Duration: 4ms
│
└── Span 3: Response returned
Duration: 48ms

### What Questions Traces Answer"Where is the slowness?"  → Database write: 1,145ms out of 1,240ms total
"Which service failed?"   → Database connection timed out at Span 2b
"What called what?"       → Gateway → Backend → Database → Response
"How long at each step?"  → Exact milliseconds per span
"Which request path?"     → This specific trace ID abc-123-xyz

### Traces in HireFlow — Specific ExamplesSCENARIO 1: Candidate form submission takes 8 secondsMetrics show: P99 latency = 8,432ms (unhealthy)
Logs show: duration_ms: 8432 for specific requestsBut WHICH part took 8 seconds?Trace for a slow submission:
Total: 8,432ms
├── Request received by pod:        12ms
├── Form schema validation:          8ms
├── FORM_VERSION ConfigMap lookup:   3ms
├── Database write (INSERT):     8,390ms ← ROOT CAUSE
└── Response sent:                  19msWithout traces: team checks application code (fine),
checks Node.js process (fine), checks pod resources (fine).
Hours wasted looking in wrong places.With traces: database write span immediately identifies
the database connection pool as the bottleneck.
Fix: increase database connection pool size.SCENARIO 2: Some submissions succeed, some fail randomlyMetrics show: 5% error rate (1 in 20 submissions failing)
Logs show: errors on some pods, not others
Traces show:Successful trace (pod hireflow-5pn8x):
Database write: 145ms ✅Failed trace (pod hireflow-jz754):
Database write: timeout after 5000ms ❌
Error: connection pool exhaustedWithout traces: seems random — hard to reproduce.
With traces: clearly correlated to one specific pod
that has a broken database connection pool.SCENARIO 3: Campus recruitment surge debuggingQuestion: "Why are some candidates experiencing 15-second
form submission times but others are fine?"Trace comparison:
Fast submission (200ms total):
└── Database write: 145ms (healthy connection)Slow submission (15,000ms total):
└── Database write: 14,800ms (connection waiting in pool queue)
→ Pool is exhausted → new requests wait for connectionsFinding: During the surge, all 10 database connections are in use.
New submissions queue and wait.
Fix: Increase pool size from 10 to 50 connections.
This finding was ONLY possible with traces.
Metrics showed high latency. Logs showed timeouts.
Only traces showed WHERE in the request path the waiting occurred.

### What Traces Cannot Tell YouTRACES CAN TELL YOU:
Exact path of one specific request through all services
Where time was spent at each step
Which service or operation caused slowness
How services depend on each otherTRACES CANNOT TELL YOU:
Overall system trends (need Metrics)
Error messages from application code (need Logs)
How many requests are slow (need Metrics)
What error text was generated (need Logs)Traces give you WHERE and HOW LONG for individual requests.

---

## How the Three Pillars Work Together

The real power of observability comes from using all three
pillars together. Each pillar answers different questions and
leads to the next.

### HireFlow Incident Response — Combined WorkflowINCIDENT: Candidates reporting form submission errors
during campus hiring surgeSTEP 1: METRICS alert you something is wrong
─────────────────────────────────────────────
Alert fires: error_rate > 5% for last 5 minutes
Metric: http_errors_total{status="500"} increased
Metric: request_duration_p99 = 8,432ms (was 200ms)What you know: Something is wrong. Affecting many users.
What you don't know: What exactly is failing or why.STEP 2: LOGS tell you what is failing
──────────────────────────────────────
kubectl logs -n recruitment -l app=hireflow | grep ERRORLog output:
{"level":"ERROR","message":"Database connection timeout",
"pod":"hireflow-jz754","duration_ms":8432}What you know: Database connections are timing out.
Specifically on pod jz754.
What you don't know: Is it the DB itself? The network?
Happens on all pods or just one?STEP 3: TRACES show you exactly where it breaks
─────────────────────────────────────────────────
Trace for failed submission:
├── Form validation: 8ms ✅
├── Database connection acquire: 8,390ms ❌ ← HERE
└── (Never reaches database write — timeout waiting for connection)Root cause identified:
Database connection pool size = 10.
During surge with 10 pods × 5 concurrent requests each = 50
simultaneous DB operations, but pool only has 10 connections.
40 requests waiting → timeout.FIX:
Increase database connection pool from 10 to 100.
Deploy updated ConfigMap.
Verify with metrics: error_rate drops to 0%.TOTAL RESOLUTION TIME WITH OBSERVABILITY: 15 minutes
TOTAL RESOLUTION TIME WITHOUT OBSERVABILITY: Hours of guessing

---

## Observability in HireFlow — Implementation Plan

### Currently Available (No Extra Tools Needed)LOGS (available now):
kubectl logs pod-name -n recruitment
kubectl logs -n recruitment -l app=hireflow
kubectl logs pod-name -n recruitment --previousThese are container stdout logs.
Our server.js already writes structured logs:
[HireFlow] Form version: v2.4.1
[HireFlow] Server running on port 3000

### Planned Tools (Future Sprints)METRICS:
Tool: Prometheus
Collects: CPU, memory, request count, error rate, latency
Visualized with: Grafana dashboards
HireFlow alert example:
Alert when pod CPU > 60% (before HPA triggers)
Alert when error rate > 1% for 5 minutesLOGS:
Tool: Loki + Fluent Bit
Fluent Bit: collects logs from all pods automatically
Loki: stores and indexes logs for querying
Grafana: visualizes logs alongside metricsTRACES:
Tool: Jaeger or Tempo
Requires: adding trace instrumentation to server.js
Node.js library: @opentelemetry/sdk-node
Shows: complete request journey including database calls

---

## The Four Questions Observability AnswersQUESTION 1: Is the system healthy right now?
Answered by: METRICS
Example: Pod CPU = 45%, Error rate = 0.1%, P99 = 180ms
Tool: Prometheus + Grafana dashboardQUESTION 2: What happened when it broke?
Answered by: LOGS
Example: "Database connection timeout at 10:32:01Z on pod jz754"
Tool: Loki + kubectl logsQUESTION 3: Where did this specific request slow down?
Answered by: TRACES
Example: "Database write span took 8,390ms of 8,432ms total"
Tool: Jaeger or TempoQUESTION 4: How do I know the fix worked?
Answered by: METRICS again
Example: P99 latency dropped from 8,432ms to 180ms after fix
Error rate dropped from 5% to 0.1%
Tool: Prometheus + Grafana