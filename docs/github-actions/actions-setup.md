# GitHub Actions CI Setup — HireFlow
## Team 02 | Sprint #3 | Assignment 4.37

---

## What is GitHub Actions?

GitHub Actions is a CI/CD automation platform built into GitHub.
It automatically runs workflows in response to repository events.

For HireFlow, GitHub Actions runs our CI pipeline automatically
every time a developer pushes code or opens a pull request.
No manual intervention required.

---

## Workflow File Location
```
.github/
└── workflows/
    └── hireflow-ci.yml   ← CI workflow (this assignment)
    └── ci-cd-pipeline.yml ← Full CI/CD pipeline (4.5, 4.9)
```

GitHub automatically detects any `.yml` file in `.github/workflows/`
and registers it as a workflow. No configuration needed beyond
placing the file in the correct location.

---

## Trigger Configuration
```yaml
on:
  push:
    branches:
      - main
      - 'assignment-*'
  pull_request:
    branches:
      - main
```

### Why `push` to main?
Every merge to main must be validated. Even if a PR passed CI,
the act of merging could theoretically introduce issues.
Running CI on the merged commit provides a final confirmation.

### Why `pull_request` to main?
PR CI runs validate proposed changes before they merge.
Combined with branch protection rules, this means:
- A PR cannot merge if CI fails
- Broken code is caught before it affects main branch
- Developers get feedback within minutes, not hours

### Why `assignment-*` branches?
Our project uses assignment branches for development.
Running CI on these branches gives early feedback during
development, not just when merging.

---

## Jobs Structure
```
hireflow-ci.yml
├── Job 1: ci-validate (runs on push + PR)
│   ├── Step 1: Checkout source code
│   ├── Step 2: Set up Node.js 18
│   ├── Step 3: Display CI environment info
│   ├── Step 4: Install dependencies (npm install)
│   ├── Step 5: Validate package.json structure
│   ├── Step 6: Run automated tests (npm test)
│   ├── Step 7: Validate server.js syntax
│   ├── Step 8: Verify application starts + health check
│   └── Step 9: CI summary
│
└── Job 2: ci-docker-check (runs on push only)
    ├── Step 1: Checkout source code
    ├── Step 2: Build Docker image
    ├── Step 3: Inspect image layers
    ├── Step 4: Run container smoke test
    └── Step 5: Docker validation summary
```

---

## Quality Gates

A quality gate is a step that stops the pipeline if it fails.
HireFlow CI has these gates in order:
```
Gate 1: Dependency installation
  → If packages fail to install → pipeline stops
  → Protects against: missing or incompatible packages

Gate 2: package.json validation
  → If package.json is malformed → pipeline stops
  → Protects against: runtime configuration errors

Gate 3: Automated tests (most critical gate)
  → If ANY test fails → pipeline stops immediately
  → No image built, no deployment possible
  → Protects against: broken business logic in production

Gate 4: Syntax validation
  → If server.js has syntax errors → pipeline stops
  → Protects against: startup crashes in containers

Gate 5: Application smoke test
  → If /health returns unhealthy → pipeline stops
  → Protects against: broken startup sequence

Gate 6: Docker build (push only)
  → If Dockerfile has errors → pipeline stops
  → Protects against: ImagePullBackOff in Kubernetes

Gate 7: Container smoke test (push only)
  → If container /health fails → pipeline stops
  → Protects against: image that builds but doesn't run
```

---

## CI Execution Flow
```
Developer pushes code
        │
        ▼
GitHub detects push event
        │
        ▼
GitHub provisions ubuntu-latest runner
        │
        ▼
Job: ci-validate starts
        │
        ├── Checkout ✅
        ├── Node.js setup ✅
        ├── npm install ✅
        ├── package.json valid ✅
        ├── Tests pass ✅ ← most critical gate
        ├── Syntax valid ✅
        └── App starts + health passes ✅
        │
        │ if push to main:
        ▼
Job: ci-docker-check starts
        │
        ├── Docker build ✅
        ├── Image inspection ✅
        └── Container smoke test ✅
        │
        ▼
CI COMPLETE — All checks passed ✅
GitHub marks commit as: ✅ Checks passed
PR can now be merged (if branch protection enabled)
```

---

## Viewing CI Results

After pushing code:
1. Go to your GitHub repository
2. Click the **"Actions"** tab
3. See your workflow run listed
4. Click the run to see each job
5. Click each job to see step-by-step output

Each step shows:
- ✅ Green checkmark = passed
- ❌ Red X = failed (click to see error)
- ⏭️ Skipped = did not run (condition not met)

---

## CI Execution Time Estimate

| Job | Steps | Estimated Duration |
|-----|-------|------------------|
| ci-validate | 9 steps | ~2-3 minutes |
| ci-docker-check | 5 steps | ~3-4 minutes |
| **Total** | **14 steps** | **~5-7 minutes** |

Fast feedback — developers know within 5 minutes whether
their code is safe to merge.

---

## What CI Guarantees After Passing

When this CI workflow shows all green checkmarks:
```
✅ Code compiles and runs without syntax errors
✅ All automated tests pass
✅ Application starts successfully
✅ /health endpoint returns healthy status
✅ /api/form-version endpoint returns form version
✅ Docker image builds without errors
✅ Containerized application passes health check

NOT guaranteed by CI (requires additional stages):
❌ No security vulnerabilities (needs trivy scan stage)
❌ No performance regressions (needs load test stage)
❌ Works correctly in staging (needs integration tests)
❌ Deployment to production works (that is CD's job)
```