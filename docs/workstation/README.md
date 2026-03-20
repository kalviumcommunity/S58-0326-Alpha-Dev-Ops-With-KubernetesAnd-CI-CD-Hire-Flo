# Workstation Documentation — HireFlow Team 02

This folder documents the DevOps workstation setup for the
HireFlow recruitment platform (Sprint #3, Assignment 4.8).

## Files

| File | Contents |
|------|---------|
| `tools-guide.md` | Why each tool exists, installation paths, command reference, troubleshooting |

## Setup Proof

| Location | Contents |
|----------|---------|
| `devops-setup/README.md` | OS details, all tools with versions, specific risks mitigated per tool |
| `devops-setup/screenshots/` | Terminal screenshots of all verification commands |
| `scripts/verify-workstation.sh` | Automated verification script |

## Run Verification
```bash
bash scripts/verify-workstation.sh
```

## Tool Summary

| Tool | Version | Purpose |
|------|---------|---------|
| Git | 2.x.x | Source control + CI trigger |
| Docker Desktop | 29.2.1 | Image build + container runtime |
| kubectl | v1.34.1 | Kubernetes CLI |
| kind | v0.22.0 | Local K8s cluster |
| Helm | v3.14.0 | K8s package manager |
| curl | Built-in | Endpoint testing |