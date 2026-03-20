# Secrets Management in CI/CD — HireFlow
## Team 02 | Sprint #3 | Assignment 4.42

---

## What Are Secrets?

Secrets are **sensitive values that must not be exposed**
to unauthorized parties. They are distinct from regular
configuration values.
```
CONFIGURATION (safe to commit):               SECRETS (never commit):
────────────────────────────────              ────────────────────────
NODE_ENV=production                           DOCKER_TOKEN=dckr_pat_xxx
FORM_VERSION=v2.4.1                           DATABASE_PASSWORD=xxxxx
PORT=3000                                     AWS_SECRET_KEY=xxxxx
NAMESPACE=recruitment                         KUBECONFIG=<cluster creds>
REPLICA_COUNT=3                               TLS_PRIVATE_KEY=xxxxx

These are non-sensitive.                      These grant access to
Anyone can read them.                         systems and resources.
Changing them doesn't                         Exposing them = breach.
compromise security.
```

---

## Why Secrets Must Never Be Committed

### The Git History Problem
```
SCENARIO: Developer commits Docker token accidentally

Step 1: Developer adds token to workflow file
  echo "token: dckr_pat_AbCdEfGhIjKlMnOpQrStUvWxYz"

Step 2: Developer pushes to GitHub
  git push origin main

Step 3: Developer realizes mistake
  git rm workflow-file.yml
  git commit -m "remove token"
  git push

PROBLEM: The token is still in Git history.
  git log --all --full-history
  git show <old-commit-hash>
  → Token visible to anyone with repo access

CORRECT FIX:
  1. Immediately revoke the token on Docker Hub
  2. Generate a new token
  3. Store new token in GitHub Secrets
  4. Use git filter-branch or BFG to remove from history
  5. Force push (risky if others have cloned)

Prevention is far easier than remediation.
```

### Specific HireFlow Risk
```
IF DOCKER_TOKEN was hardcoded in workflow file:

Attack scenario:
  1. Attacker forks public repository
  2. Views .github/workflows/hireflow-ci.yml
  3. Copies DOCKER_TOKEN value
  4. Runs: docker login -u abhich98 --password-stdin
     (pastes token)
  5. Pushes malicious image:
     docker push abhich98/hireflow-backend:latest
  6. Next Kubernetes deployment pulls malicious image
  7. All HireFlow pods run attacker's code
  8. Candidate data compromised

IMPACT:
  - 8,000 candidate applications exposed
  - Form submission data stolen
  - Complete platform compromise

WITH GITHUB SECRETS:
  - Token never in repository
  - Attacker cannot access it even with repo read access
  - Only GitHub Actions runner decrypts it at runtime
  - Only this specific workflow can use it
```

---

## How GitHub Secrets Work Internally
```
STORAGE:
  1. You enter secret value in GitHub UI
  2. GitHub encrypts it using libsodium sealed box
  3. Encrypted value stored in GitHub's secure vault
  4. Original value never stored in plaintext

INJECTION AT RUNTIME:
  1. Workflow runs on GitHub Actions runner
  2. Runner requests secret from GitHub vault
  3. GitHub authenticates the runner
  4. Encrypted secret transmitted over TLS
  5. Decrypted in memory on runner
  6. Passed to step as environment variable
  7. Never written to disk
  8. Automatically masked in all log output

MASKING:
  If secret value appears anywhere in log output:
  GitHub replaces it with ***
  Even accidental prints are protected

SCOPE:
  Secrets are available only to:
  - Workflows in the repository they are defined in
  - Steps that explicitly reference them
  - Cannot be accessed by forked PRs (security feature)
```

---

## Secrets Used in HireFlow CI/CD

| Secret Name | Purpose | Risk if Exposed |
|-------------|---------|----------------|
| `DOCKER_USERNAME` | Docker Hub username for authentication | Low — username is semi-public |
| `DOCKER_TOKEN` | Docker Hub access token for push authorization | **Critical** — allows pushing malicious images |

### Why Access Token Instead of Password
```
DOCKER_PASSWORD (bad):
  - Full account access if compromised
  - Cannot scope to specific permissions
  - Changing password breaks all services using it
  - Cannot be individually revoked

DOCKER_TOKEN (correct):
  - Scoped to specific permissions (push only)
  - Individually revocable without affecting account
  - Separate token per service (one for GitHub, one for local)
  - Rotation does not affect other services
  - This is the principle of least privilege:
    grant only the minimum access required
```

---

## Secret Injection Flow in HireFlow Pipeline
```
GitHub Secrets Vault
  │
  │ Encrypted: DOCKER_USERNAME = abhich98
  │ Encrypted: DOCKER_TOKEN = dckr_pat_xxx...
  │
  │ Runner requests secrets
  ▼
GitHub Actions Runner (ubuntu-latest)
  │
  │ Decrypted in memory:
  │   DOCKER_USERNAME → abhich98
  │   DOCKER_TOKEN    → dckr_pat_xxx...
  │
  ▼
docker/login-action@v3
  │ username: ${{ secrets.DOCKER_USERNAME }}
  │ password: ${{ secrets.DOCKER_TOKEN }}
  │
  ▼
Docker Hub Authentication
  │ Credentials verified over HTTPS
  │ Authentication token stored in memory
  │ Original credentials discarded
  │
  ▼
docker push abhich98/hireflow-backend:sha-a3f91b2
  │ Uses memory-stored auth token
  │ No credentials in push command
  │
  ▼
Image pushed to registry ✅
Credentials never in logs ✅
Credentials never in files ✅
```

---

## What Never to Do — Anti-Patterns

### Anti-Pattern 1: Hardcoded in Workflow
```yaml
# ❌ NEVER DO THIS
- name: Login to Docker Hub
  run: |
    docker login -u abhich98 -p dckr_pat_AbCdEfGhIj...
    # This token is now visible to anyone with repo access
    # It is in git history forever
```

### Anti-Pattern 2: Environment Variable in Workflow
```yaml
# ❌ ALSO WRONG
env:
  DOCKER_TOKEN: dckr_pat_AbCdEfGhIj...
  # Still visible in the YAML file
  # Still in git history
```

### Anti-Pattern 3: Printed in Log
```yaml
# ❌ ACCIDENTAL EXPOSURE
- name: Debug
  run: echo "Token is $DOCKER_TOKEN"
  # Even though GitHub masks this automatically,
  # the intent to print secrets is wrong practice
```

### Correct Pattern: Runtime Injection
```yaml
# ✅ CORRECT
- name: Login to Docker Hub
  uses: docker/login-action@v3
  with:
    username: ${{ secrets.DOCKER_USERNAME }}
    password: ${{ secrets.DOCKER_TOKEN }}
  # Values never in YAML file
  # Injected at runtime from GitHub vault
  # Never printed in logs
  # Masked if accidentally referenced
```

---

## Configuration vs Secrets — Decision Guide
```
ASK THESE QUESTIONS:

1. Would exposing this value allow someone to access a system?
   YES → Secret (use GitHub Secrets)
   NO  → Configuration (can be in YAML or ConfigMap)

2. Is this value different per environment but not sensitive?
   YES → Environment variable or ConfigMap
   NO  → Might be a secret

3. Does this value grant permissions or authenticate something?
   YES → Secret
   NO  → Configuration

HIREFLOW EXAMPLES:
  FORM_VERSION=v2.4.1     → ConfigMap (not sensitive)
  NODE_ENV=production     → ConfigMap (not sensitive)
  PORT=3000               → ConfigMap (not sensitive)
  DOCKER_TOKEN=xxx        → GitHub Secret (grants push access)
  DATABASE_PASSWORD=xxx   → Kubernetes Secret (grants DB access)
  TLS_PRIVATE_KEY=xxx     → Kubernetes Secret (encrypts traffic)
```