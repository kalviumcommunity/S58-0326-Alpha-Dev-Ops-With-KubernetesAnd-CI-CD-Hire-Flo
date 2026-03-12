# HireFlow CI/CD Pipeline — Team 02

## Pipeline Overview

This repository uses GitHub Actions to automate the build, test, and 
Docker image creation stages for the HireFlow recruitment platform.

## Pipeline Stages

| Stage | Purpose |
|-------|---------|
| Build & Test | Installs dependencies, runs unit tests and lint checks |
| Docker Build | Builds a Docker image tagged with Git SHA for version tracing |
| Notify | Prints deployment summary with commit hash and branch name |

## Why CI/CD?

Our recruitment platform faces seasonal hiring surges. Manual deployments 
caused downtime during peak load. This pipeline ensures:
- Every push is automatically validated
- Docker images are tagged with Git SHA (linked to form schema version)
- No manual steps between code commit and deployment readiness

## Trigger

Pipeline runs on every push and pull request to `main` branch.

## Form Version Tracking

Each Docker image tag maps to a form schema version (e.g., v2.4.1), 
stored in a Kubernetes ConfigMap. This solves the recruiter problem of 
not knowing which form a candidate filled out after updates.