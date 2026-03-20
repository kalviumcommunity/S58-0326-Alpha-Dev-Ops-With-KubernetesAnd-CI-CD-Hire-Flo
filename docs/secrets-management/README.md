# Secrets Management Documentation — HireFlow Team 02

This folder documents secrets management practices for the
HireFlow recruitment platform (Sprint #3, Assignment 4.42).

## Files

| File | Contents |
|------|---------|
| `secrets-guide.md` | What secrets are, why never commit, GitHub Secrets internals, injection flow, anti-patterns, config vs secrets guide |

## Workflow File

| File | Location | Purpose |
|------|----------|---------|
| `hireflow-secure-pipeline.yml` | `.github/workflows/` | Demonstrates secure secret injection with masking, hygiene scan |

## Secrets Configured in This Repository

| Secret | Stored In | Used For |
|--------|-----------|---------|
| `DOCKER_USERNAME` | GitHub Secrets | Docker Hub auth username |
| `DOCKER_TOKEN` | GitHub Secrets | Docker Hub push authorization |

## Secret Values
Secret values are NEVER stored in this repository.
They exist only in GitHub's encrypted secrets vault.
They are decrypted in memory on the runner at runtime only.

## Verify Secrets Are Set
Go to: Settings → Secrets and variables → Actions
Both DOCKER_USERNAME and DOCKER_TOKEN must be listed.