# Observability Documentation — HireFlow Team 02

This folder documents observability concepts for the HireFlow
recruitment platform (Sprint #3, Assignment 4.43).

## Files

| File | Contents |
|------|---------|
| `observability-concepts.md` | Full three-pillar explanation with HireFlow-specific scenarios, combined incident workflow, implementation plan |
| `observability-signals.md` | When to use each signal, signal characteristics comparison, Kubernetes commands available now |

## The Three Pillars
```
METRICS          LOGS             TRACES
────────────     ────────────     ────────────────
Numbers/trends   Events/text      Request journeys
What/When        What happened    Where/How long
Prometheus       Loki/kubectl     Jaeger/Tempo
Always on        On events        Per request
```

## Key Insight for HireFlow

During campus hiring surge:
- METRICS tell you: CPU > 60%, HPA scaling to 7 pods
- LOGS tell you: specific pod showing database timeout errors
- TRACES tell you: database connection acquire taking 8,390ms

All three together → root cause in 15 minutes
Any one alone → hours of guessing