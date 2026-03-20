# GitHub Actions Documentation — HireFlow Team 02

This folder documents the GitHub Actions CI setup for the
HireFlow recruitment platform (Sprint #3, Assignment 4.37).

## Files

| File | Contents |
|------|---------|
| `actions-setup.md` | Workflow structure, trigger configuration, quality gates, CI execution flow, what CI guarantees |

## Workflow File

| File | Location | Purpose |
|------|----------|---------|
| `hireflow-ci.yml` | `.github/workflows/` | CI pipeline — runs on push and PR |

## Quick Reference
```bash
# View CI runs in terminal (requires GitHub CLI)
gh run list

# View latest run
gh run view

# Watch a run in progress
gh run watch
```

## CI Jobs

| Job | Trigger | Purpose |
|-----|---------|---------|
| ci-validate | push + PR | Code quality: install, test, syntax, smoke |
| ci-docker-check | push only | Docker: build, inspect, container smoke test |

## Viewing Results
Go to: github.com/your-repo → Actions tab → Select run