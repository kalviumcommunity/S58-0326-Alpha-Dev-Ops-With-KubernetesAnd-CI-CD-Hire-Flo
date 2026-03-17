# Container Debugging Documentation — HireFlow Team 02

This folder contains container build, run, and debugging documentation
for the HireFlow recruitment platform (Sprint #3, Assignment 4.15).

## Files

| File | Contents |
|------|---------|
| `debugging-guide.md` | Full debug workflow, command reference, 5 common issues with fixes, decision tree |
| `run-configurations.md` | Standard run configs, flag reference, port mapping, Docker vs Kubernetes mapping |

## Script

| File | Location | Purpose |
|------|----------|---------|
| `container-debug.sh` | `scripts/` | End-to-end build → run → inspect → debug → fix workflow |

## How to Run the Debug Script
```bash
# From repository root
chmod +x scripts/container-debug.sh
bash scripts/container-debug.sh
```

## Key Debugging Commands
```bash
docker logs hireflow-test          # View app output
docker exec hireflow-test env      # Check env variables
docker exec -it hireflow-test sh   # Open shell inside container
docker inspect hireflow-test       # Full container metadata
docker stats hireflow-test --no-stream  # Resource usage
```