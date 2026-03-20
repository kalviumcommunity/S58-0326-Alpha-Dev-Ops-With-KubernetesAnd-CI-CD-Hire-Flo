# CI/CD Pipeline Design & Workflow Stages — HireFlow
## Team 02 | Sprint #3 | Assignment 4.36

---

## What is a CI/CD Pipeline?

A CI/CD pipeline is a structured sequence of automated stages
that a code change must pass through before it reaches users.

Each stage has:
- A single, clear purpose
- A defined input (what it receives)
- A defined output (what it produces)
- A gate (pass = continue, fail = stop)

Pipelines are not random collections of scripts.
They are intentionally ordered systems where each stage
builds confidence that the next stage is safe to execute.

---

## HireFlow Pipeline — Complete Stage Map
```
Developer Workstation
        │
        │ git push / Pull Request opened
        ▼
═══════════════════════════════════════════════════════════
              CONTINUOUS INTEGRATION (CI)
        "Is this code safe and ready to ship?"
═══════════════════════════════════════════════════════════
        │
        ▼
┌─────────────────────────────────────────────────────┐
│  STAGE 1: Code Checkout                             │
│                                                     │
│  Input:  Git commit SHA (e.g. a3f91b2)              │
│  Action: Clone repository at exact commit           │
│  Output: Source code on CI runner                   │
│  Gate:   Repository accessible? Code exists?        │
│  Risk mitigated: Stale or wrong code version        │
│                                                     │
│  Runs on: Every push, every PR                      │
└──────────────────────┬──────────────────────────────┘
                       │ if checkout succeeds
                       ▼
┌─────────────────────────────────────────────────────┐
│  STAGE 2: Dependency Installation                   │
│                                                     │
│  Input:  Source code + package.json                 │
│  Action: npm install (installs all packages)        │
│  Output: node_modules/ ready for build and test     │
│  Gate:   All dependencies resolve without error?    │
│  Risk mitigated: Missing or incompatible packages   │
│                                                     │
│  Runs on: Every push, every PR                      │
└──────────────────────┬──────────────────────────────┘
                       │ if install succeeds
                       ▼
┌─────────────────────────────────────────────────────┐
│  STAGE 3: Automated Testing                         │
│                                                     │
│  Input:  Source code + installed dependencies       │
│  Action: npm test (runs all unit tests)             │
│  Output: Test report (pass / fail)                  │
│  Gate:   ALL tests pass? (zero tolerance for fail)  │
│  Risk mitigated: Broken logic reaching production   │
│                                                     │
│  ⚠️ QUALITY GATE: If ANY test fails →               │
│     Pipeline stops immediately                      │
│     No image is built                               │
│     No deployment happens                           │
│     Developer is notified                           │
│                                                     │
│  Runs on: Every push, every PR                      │
└──────────────────────┬──────────────────────────────┘
                       │ if all tests pass
                       ▼
┌─────────────────────────────────────────────────────┐
│  STAGE 4: Code Quality Check (Lint)                 │
│                                                     │
│  Input:  Source code                                │
│  Action: Lint analysis (style + syntax check)       │
│  Output: Lint report (pass / fail)                  │
│  Gate:   Zero lint errors?                          │
│  Risk mitigated: Poor code quality merging to main  │
│                                                     │
│  Runs on: Every push, every PR                      │
└──────────────────────┬──────────────────────────────┘
                       │ if lint passes
                       │ (PR only stops here — no image built for PRs)
                       │ (Main branch push continues below)
                       ▼
┌─────────────────────────────────────────────────────┐
│  STAGE 5: Docker Image Build                        │
│                                                     │
│  Input:  Validated source code (passed all gates)   │
│  Action: docker build -t hireflow:sha-a3f91b2 .    │
│  Output: Docker image (immutable artifact)          │
│  Gate:   Image builds without error?                │
│  Risk mitigated: Broken Dockerfile in production    │
│                                                     │
│  KEY PRINCIPLE:                                     │
│  Image is built ONCE from validated code            │
│  The SAME image runs in all environments            │
│  No rebuilding at deployment time                   │
│                                                     │
│  Runs on: Main branch push ONLY (not PRs)          │
└──────────────────────┬──────────────────────────────┘
                       │ if build succeeds
                       ▼
┌─────────────────────────────────────────────────────┐
│  STAGE 6: Image Tagging & Registry Push             │
│                                                     │
│  Input:  Built Docker image                         │
│  Action: Tag with 3 identifiers:                    │
│          sha-a3f91b2 → exact git commit (immutable) │
│          v2.4.1      → form schema version          │
│          latest      → floating convenience tag     │
│          docker push all 3 tags to Docker Hub       │
│  Output: Image available in registry for CD         │
│  Gate:   All tags pushed successfully?              │
│  Risk mitigated: Unversioned or untraceable images  │
│                                                     │
│  ── THIS IS WHERE CI ENDS ──                        │
│  ── ARTIFACT IS READY IN REGISTRY ──                │
│                                                     │
│  Runs on: Main branch push ONLY                     │
└──────────────────────┬──────────────────────────────┘
                       │
                       │ HANDOFF: CI → CD
                       │ Registry is the boundary
                       │
═══════════════════════════════════════════════════════════
             CONTINUOUS DEPLOYMENT (CD)
       "How do we safely deliver this to users?"
═══════════════════════════════════════════════════════════
                       │
                       ▼
┌─────────────────────────────────────────────────────┐
│  STAGE 7: Artifact Verification                     │
│                                                     │
│  Input:  Image tag from CI stage (sha-a3f91b2)      │
│  Action: Confirm image exists in Docker Hub         │
│  Output: Verified artifact reference                │
│  Gate:   Image pullable from registry?              │
│  Risk mitigated: Deploying an image that doesn't    │
│                  exist or failed to push            │
│                                                     │
│  KEY PRINCIPLE:                                     │
│  CD never rebuilds code                             │
│  CD only uses what CI already produced              │
│                                                     │
│  Runs on: Main branch push ONLY                     │
└──────────────────────┬──────────────────────────────┘
                       │ if image verified
                       ▼
┌─────────────────────────────────────────────────────┐
│  STAGE 8: Kubernetes Manifest Update                │
│                                                     │
│  Input:  Verified image tag + k8s manifest files    │
│  Action: Update image field in deployment.yaml      │
│          image: abhich98/hireflow-backend:sha-a3f91b│
│  Output: Updated manifest ready to apply            │
│  Gate:   Manifest valid YAML? Image tag correct?    │
│  Risk mitigated: Wrong image version deployed       │
│                                                     │
│  Runs on: Main branch push ONLY                     │
└──────────────────────┬──────────────────────────────┘
                       │ if manifest valid
                       ▼
┌─────────────────────────────────────────────────────┐
│  STAGE 9: Cluster Deployment                        │
│                                                     │
│  Input:  Updated Kubernetes manifests               │
│  Action: kubectl apply -f k8s/                      │
│          Kubernetes API Server receives desired state│
│  Output: Rolling update initiated in cluster        │
│  Gate:   kubectl apply returns success?             │
│  Risk mitigated: Configuration errors in manifests  │
│                                                     │
│  Rolling update strategy:                           │
│  maxUnavailable: 1 (1 pod offline max during update)│
│  maxSurge: 1 (1 extra pod max during update)        │
│  → Zero downtime for candidates submitting forms    │
│                                                     │
│  Runs on: Main branch push ONLY                     │
└──────────────────────┬──────────────────────────────┘
                       │ if deployment applied
                       ▼
┌─────────────────────────────────────────────────────┐
│  STAGE 10: Deployment Verification                  │
│                                                     │
│  Input:  Deployed Kubernetes workload               │
│  Action: kubectl rollout status deployment/hireflow  │
│          Monitors until all pods are healthy        │
│  Output: Confirmation that rollout succeeded        │
│  Gate:   All pods Running and passing probes?       │
│  Risk mitigated: Silent deployment failures         │
│                                                     │
│  Kubernetes handles internally (outside pipeline):  │
│  → Liveness probe: restarts unhealthy containers   │
│  → Readiness probe: gates traffic to ready pods    │
│  → ReplicaSet: maintains desired replica count     │
│  → HPA: scales pods during hiring surges            │
│                                                     │
│  Runs on: Main branch push ONLY                     │
└──────────────────────┬──────────────────────────────┘
                       │ rollout confirmed
                       ▼
        APPLICATION AVAILABLE TO USERS ✅
        Candidates can submit applications
        Recruiters can view form versions
```

---

## CI vs CD — Explicit Boundary
```
CI STAGES (Stages 1-6)          CD STAGES (Stages 7-10)
────────────────────────────    ────────────────────────────
Stage 1: Code Checkout          Stage 7: Artifact Verification
Stage 2: Dependency Install     Stage 8: Manifest Update
Stage 3: Automated Testing      Stage 9: Cluster Deployment
Stage 4: Lint Check             Stage 10: Deployment Verification
Stage 5: Docker Image Build
Stage 6: Image Tag + Push
────────────────────────────    ────────────────────────────
Triggered by: any push/PR       Triggered by: CI success only
Produces: Docker image          Consumes: Docker image from CI
Answers: "Safe to merge?"       Answers: "Safe to run?"
Affects: Registry only          Affects: Live cluster
Failure impact: Blocks merge    Failure impact: Triggers rollback
```

---

## Stage Ordering — Why This Sequence?
```
WHY Checkout before Install?
  You cannot install deps without the source code.
  Obvious — but ordering enforces this explicitly.

WHY Install before Test?
  Tests require the application dependencies to run.
  Running tests without node_modules would always fail.

WHY Test before Build?
  Building an image from broken code wastes time and
  creates a broken artifact in the registry.
  Tests gate the build — only validated code is packaged.

WHY Lint after Test?
  Tests catch functional bugs (more critical).
  Lint catches style issues (less critical but important).
  Functional correctness is verified first.

WHY Build before Push?
  You cannot push an image that doesn't exist yet.
  The build must succeed before storage is used.

WHY Artifact Verify before Deploy?
  CD must confirm CI completed successfully.
  Deploying a non-existent image causes ImagePullBackOff
  in Kubernetes — a preventable production failure.

WHY Manifest Update before Apply?
  Applying old manifests with old image tag =
  "deploying" with no actual change.
  The manifest must reference the new image first.

WHY Verify after Deploy?
  kubectl apply returning success only means the API
  Server accepted the request — not that pods are healthy.
  Verification confirms the actual rollout completed.
```

---

## Which Stages Run When?
```
TRIGGER: Pull Request opened/updated
  ✅ Stage 1: Code Checkout
  ✅ Stage 2: Dependency Install
  ✅ Stage 3: Automated Testing
  ✅ Stage 4: Lint Check
  ❌ Stage 5: Docker Build      ← NOT on PRs
  ❌ Stage 6: Image Push        ← NOT on PRs
  ❌ Stages 7-10: CD            ← NOT on PRs

  Reason: PRs need quality validation only.
  Building images for unmerged code wastes resources
  and pollutes the registry with unreviewed code.

TRIGGER: Push to main (PR merged)
  ✅ Stage 1: Code Checkout
  ✅ Stage 2: Dependency Install
  ✅ Stage 3: Automated Testing
  ✅ Stage 4: Lint Check
  ✅ Stage 5: Docker Build
  ✅ Stage 6: Image Push
  ✅ Stage 7: Artifact Verify
  ✅ Stage 8: Manifest Update
  ✅ Stage 9: Cluster Deploy
  ✅ Stage 10: Deployment Verify

  Reason: Only reviewed and approved code
  should become a deployable artifact.
```

---

## Why This Pipeline Design Suits HireFlow
```
PROBLEM 1: Seasonal hiring surges (8000+ apps/day)
  Pipeline solution:
  Stage 9 applies HPA config → auto-scaling enabled
  Stage 10 verifies HPA is active before marking success
  Result: Pipeline ensures scaling is configured before
          any hiring surge can occur

PROBLEM 2: Form version traceability
  Pipeline solution:
  Stage 6 tags image with BOTH git SHA and form version
  SHA: sha-a3f91b2 → exact commit → exact code
  Version: v2.4.1 → form schema → recruiter readable
  Result: Every deployed image traceable to exact form

PROBLEM 3: Zero-downtime deployments
  Pipeline solution:
  Stage 9 applies rolling update strategy
  maxUnavailable: 1, maxSurge: 1
  Stage 10 monitors rollout before declaring success
  Result: Candidates never see errors during updates

PROBLEM 4: Bad code reaching production
  Pipeline solution:
  Stage 3 quality gate stops pipeline on ANY test failure
  No image built → no deployment possible
  Result: Broken code physically cannot reach production
```

---

## How This Pipeline Scales as Project Grows
```
CURRENT (Sprint #3):
  10 stages, 1 environment, 1 cluster

FUTURE SCALING:
  Add integration test stage after unit tests
  Add security scanning stage after image build
    (trivy scan for CVEs in image layers)
  Add staging environment deployment before production
  Add manual approval gate before production deploy
  Add smoke test stage after each deployment
  Add notification stage (Slack/email on failure)

SCALED PIPELINE (future):
  Stage 1:  Checkout
  Stage 2:  Install
  Stage 3:  Unit Tests       ← current
  Stage 4:  Lint
  Stage 5:  Build
  Stage 6:  Security Scan    ← new: CVE scanning
  Stage 7:  Push to Registry
  Stage 8:  Deploy Staging   ← new: staging environment
  Stage 9:  Integration Tests← new: test on staging
  Stage 10: Manual Approval  ← new: human gate
  Stage 11: Deploy Production← current stage 9
  Stage 12: Smoke Tests      ← new: post-deploy tests
  Stage 13: Verify           ← current stage 10
  Stage 14: Notify           ← new: alert on failure
```

---

## Risk Mitigation Per Stage

| Stage | Risk Mitigated | Without This Stage |
|-------|---------------|-------------------|
| 1. Checkout | Wrong code version | Stale code deployed |
| 2. Install | Missing dependencies | Runtime crashes |
| 3. Testing | Broken business logic | Candidates see errors |
| 4. Lint | Poor code quality | Maintenance debt |
| 5. Build | Broken Dockerfile | ImagePullBackOff in K8s |
| 6. Tag + Push | Untraceable images | Cannot rollback safely |
| 7. Verify artifact | Non-existent image | Deployment fails silently |
| 8. Update manifest | Wrong image deployed | Old version runs silently |
| 9. Deploy | Manual deployment errors | Config drift, downtime |
| 10. Verify rollout | Silent failures | Broken pods serving traffic |