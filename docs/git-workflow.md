# Git Workflow — HireFlow Team 02

## Why Structured Git Matters for HireFlow

During campus recruitment season, multiple team members push changes 
simultaneously — new form fields, pipeline updates, Kubernetes configs. 
Without structured branching, these changes collide, break builds, and 
create deployment confusion.

Our Git workflow ensures every change is isolated, reviewed, and traceable.

---

## Our Branching Model (GitHub Flow — Simplified)
```
PRODUCTION STATE
      │
    main  ←──────────────────────────── always deployable
      │
      ├── feature/candidate-apply-form
      │         └── PR → reviewed → merged → branch deleted
      │
      ├── fix/form-version-display-bug
      │         └── PR → reviewed → merged → branch deleted
      │
      ├── ci/add-docker-build-stage
      │         └── PR → reviewed → merged → branch deleted
      │
      └── docs/git-branching-strategy
                └── PR → reviewed → merged → branch deleted
```

### Why Not Git Flow (with develop branch)?
Git Flow adds a `develop` branch between features and main. For our 
team size and sprint scope, this adds complexity without benefit. 
GitHub Flow keeps `main` as the single integration point and is 
better suited for CI/CD pipelines where every merge can trigger a deploy.

---

## Complete PR Lifecycle
```
Step 1: Pull latest main
        git checkout main
        git pull origin main

Step 2: Create feature branch
        git checkout -b feature/your-feature-name

Step 3: Make changes, commit with conventions
        git add .
        git commit -m "feat(scope): describe what and why"

Step 4: Push branch
        git push origin feature/your-feature-name

Step 5: Open PR on GitHub
        - Clear title following convention
        - Description: what changed, why, how to test

Step 6: Review + merge via GitHub UI

Step 7: Delete branch after merge
        git branch -d feature/your-feature-name
```

---

## Commit Message Deep Dive

### Format
```
<type>(<scope>): <imperative short description>

[optional body: explain WHY, not WHAT]

[optional footer: references, breaking changes]
```

### Real Examples from HireFlow
```
feat(apply-form): add form version v2.4.1 stamp to submission payload

The recruiter dashboard needs to show which form schema a candidate
filled out. Each submission now includes FORM_VERSION from the
Kubernetes ConfigMap. This allows recruiters to compare applications
fairly across form versions.

Closes #14
```
```
ci(pipeline): add docker image build stage with git-sha tagging

Images are now tagged with the commit SHA to enable precise
form-version-to-image mapping. Solves the recruiter problem of
not knowing which form was active during a deployment.
```
```
fix(hpa): lower cpu threshold from 80 to 60 percent

During the last campus hiring surge, HPA triggered too late and
the platform slowed before new pods came online. Lowering the
threshold gives Kubernetes more headroom to scale proactively.
```

---

## What Makes a Good vs Bad Branch Name

| ❌ Bad | ✅ Good |
|--------|---------|
| `my-branch` | `feature/candidate-apply-form` |
| `test` | `fix/hpa-threshold-too-high` |
| `priya-changes` | `docs/git-workflow-guide` |
| `sprint3` | `ci/github-actions-docker-stage` |
| `wip` | `refactor/dockerfile-base-image` |

---

## Protecting main Branch (Recommended Settings)

On GitHub → Settings → Branches → Add rule for `main`:
- ✅ Require pull request before merging
- ✅ Require at least 1 approval
- ✅ Require status checks to pass (CI pipeline)
- ✅ Do not allow direct pushes