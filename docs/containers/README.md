# Containers Documentation — HireFlow Team 02

This folder contains containerization concept documentation for the
HireFlow recruitment platform (Sprint #3, Assignment 4.12).

## Files

| File | Contents |
|------|---------|
| `containerization-concepts.md` | Core concepts: what containers are, containers vs VMs, how they work internally, image vs container distinction |
| `hireflow-container-strategy.md` | How HireFlow specifically uses containers to solve surge scaling and form version traceability |

## Key Concepts Covered

- Why containers emerged (environment inconsistency, slow deployments)
- Container internals: Linux namespaces and cgroups
- Containers vs Virtual Machines comparison
- Container image vs running container distinction
- Image registry as a distribution mechanism
- When to use and when NOT to use containers

## Next Steps

These concepts are implemented hands-on in:
- `4.13` — Docker Architecture: Images, Containers, and Layers
- `4.14` — Writing Dockerfiles for HireFlow
- `4.15` — Building and Running Containers Locally