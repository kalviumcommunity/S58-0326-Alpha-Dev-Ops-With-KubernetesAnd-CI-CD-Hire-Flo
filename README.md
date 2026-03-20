# Main Branch
# HireFlow — Recruitment Platform
### Team 02 | Sprint #3: DevOps with Kubernetes & CI/CD

---

## Problem Statement

A recruitment platform experiences seasonal hiring surges during campus 
recruitment season and holiday hiring. The system slows under peak submission 
loads, and recruiters cannot track which version of the application form 
candidates filled out after updates are deployed.

## Our Solution

A fully automated DevOps pipeline using Docker, Kubernetes, and GitHub Actions 
that ensures:
- Auto-scaling during traffic surges via Kubernetes HPA
- Zero-downtime deployments using rolling updates
- Git SHA-based image tagging for form version traceability

---

## Repository Structure
```
hireflow-devops/
├── .github/workflows/    → CI/CD pipeline (GitHub Actions)
├── src/frontend/         → Candidate-facing React application
├── src/backend/          → Node.js recruitment API
├── k8s/                  → Kubernetes manifests
├── docs/                 → Architecture and design documentation
├── CONTRIBUTING.md       → Branching strategy and commit conventions
├── PIPELINE.md           → CI/CD pipeline documentation
└── README.md             → This file
```

---

## Branching Strategy

We follow a **feature-branch workflow**:
```
main                    ← always stable, protected
 ├── feature/xyz        ← new features
 ├── fix/xyz            ← bug fixes
 ├── ci/xyz             ← pipeline changes
 ├── docs/xyz           ← documentation
 └── hotfix/xyz         ← critical production fixes
```

All changes enter `main` exclusively through Pull Requests.
Direct pushes to `main` are not allowed.

---

## Commit Convention

We use [Conventional Commits](https://www.conventionalcommits.org/):
```
feat(scope): description       ← new feature
fix(scope): description        ← bug fix  
docs(scope): description       ← documentation
ci(scope): description         ← pipeline changes
refactor(scope): description   ← restructure
```

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | React.js |
| Backend | Node.js + Express |
| Containerization | Docker |
| Orchestration | Kubernetes (kind locally, cloud in prod) |
| CI/CD | GitHub Actions |
| Registry | GitHub Container Registry (GHCR) |
| Config Management | Kubernetes ConfigMaps + Secrets |

---

## CI/CD Pipeline

Every push to `main` triggers:
1. **Build & Test** — install dependencies, run tests, lint
2. **Docker Build** — create image tagged with Git SHA
3. **Deploy** — rolling update to Kubernetes cluster

---

## Team

**Team 02** — Sprint #3 DevOps with Kubernetes & CI/CD