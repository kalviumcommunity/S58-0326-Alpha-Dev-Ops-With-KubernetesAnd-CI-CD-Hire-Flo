# Contributing to HireFlow — Team 02

This document defines how all team members should work with this repository.
Following these conventions ensures a clean, traceable, and reviewable Git history.

---

## Branch Naming Convention

All branches must follow this format:
```
<type>/<short-description>
```

| Type | When to Use | Example |
|------|-------------|---------|
| `feature/` | New functionality | `feature/candidate-apply-form` |
| `fix/` | Bug fix | `fix/form-version-mismatch` |
| `docs/` | Documentation only | `docs/pipeline-readme` |
| `ci/` | Pipeline or workflow changes | `ci/github-actions-setup` |
| `refactor/` | Code restructure, no new features | `refactor/dockerfile-layers` |
| `hotfix/` | Critical production fix | `hotfix/hpa-config-error` |

### Rules
- `main` branch is always stable and deployable
- Never push directly to `main` — always use a Pull Request
- One PR = one logical unit of work
- Delete branches after merging

---

## Commit Message Convention

We follow the **Conventional Commits** standard:
```
<type>(<scope>): <short description>
```

### Types

| Type | Purpose |
|------|---------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation changes |
| `ci` | CI/CD pipeline changes |
| `refactor` | Restructuring without behavior change |
| `test` | Adding or updating tests |
| `chore` | Maintenance (dependencies, configs) |

### Examples of Good Commit Messages
```
feat(apply-form): add form version stamp to application submission
fix(hpa): correct CPU threshold from 80% to 60% for surge handling
docs(readme): add repository structure and branching guide
ci(pipeline): add docker build stage with git-sha image tagging
refactor(dockerfile): reduce image size by using node:18-alpine base
```

### Examples of Bad Commit Messages (Never Do This)
```
updated stuff
fixed bug
changes
wip
asdf
my changes for today
```

---

## Pull Request Process

1. Create a branch from `main` using the naming convention above
2. Make small, focused commits — one idea per commit
3. Write a clear PR title and description (see template below)
4. Request review before merging
5. Delete branch after merge

### PR Title Format
```
<type>(<scope>): <what this PR does>
```
Example: `docs(contributing): add branching strategy and commit conventions`

---

## Repository Structure
```
hireflow-devops/
├── .github/
│   └── workflows/
│       └── ci-cd.yml          # GitHub Actions CI/CD pipeline
├── src/
│   ├── frontend/              # React frontend (candidate portal)
│   └── backend/               # Node.js API server
├── k8s/
│   ├── deployment.yaml        # Kubernetes Deployment manifest
│   ├── service.yaml           # Kubernetes Service manifest
│   ├── configmap.yaml         # Form version config
│   └── hpa.yaml               # Horizontal Pod Autoscaler
├── docs/
│   └── architecture.md        # System design and flow diagrams
├── CONTRIBUTING.md            # This file — branching and commit guide
├── PIPELINE.md                # CI/CD pipeline documentation
└── README.md                  # Project overview
```
