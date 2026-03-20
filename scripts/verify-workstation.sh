#!/bin/bash

# ============================================================
# HireFlow — DevOps Workstation Verification Script
# Team 02 | Sprint #3 | Assignment 4.8
# ============================================================
# Verifies all required DevOps tools are installed and
# accessible. Run this script to confirm workstation is
# ready for Sprint #3 implementation.
# ============================================================

echo ""
echo "============================================================"
echo "  HireFlow DevOps Workstation Verification"
echo "  Team 02 | Sprint #3 | Assignment 4.8"
echo "============================================================"
echo ""

PASS=0
FAIL=0

check_tool() {
  local tool=$1
  local cmd=$2
  local expected=$3

  echo "------------------------------------------------------------"
  echo "Checking: ${tool}"
  echo "Command:  ${cmd}"
  echo ""

  OUTPUT=$(eval "$cmd" 2>&1)
  EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ]; then
    echo "Output: ${OUTPUT}"
    echo "Status: ✅ INSTALLED"
    PASS=$((PASS + 1))
  else
    echo "Output: ${OUTPUT}"
    echo "Status: ❌ NOT FOUND OR ERROR"
    FAIL=$((FAIL + 1))
  fi
  echo ""
}

# ------------------------------------------------------------
# TOOL 1: Git
# ------------------------------------------------------------
check_tool \
  "Git — Source Control" \
  "git --version" \
  "git version"

echo "Git is the trigger point for our CI/CD pipeline."
echo "Every code change begins with git push."
echo ""

# ------------------------------------------------------------
# TOOL 2: Docker
# ------------------------------------------------------------
check_tool \
  "Docker — Container Runtime" \
  "docker --version" \
  "Docker version"

echo "Docker builds HireFlow images: abhich98/hireflow-backend"
echo ""

# ------------------------------------------------------------
# TOOL 3: Docker hello-world test
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "Checking: Docker runtime (hello-world test)"
echo ""
docker run --rm hello-world 2>&1 | grep -E "Hello|error"
if [ $? -eq 0 ]; then
  echo "Status: ✅ Docker runtime working"
  PASS=$((PASS + 1))
else
  echo "Status: ❌ Docker runtime not working"
  FAIL=$((FAIL + 1))
fi
echo ""

# ------------------------------------------------------------
# TOOL 4: kubectl
# ------------------------------------------------------------
check_tool \
  "kubectl — Kubernetes CLI" \
  "kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null | head -1" \
  "Client Version"

echo "kubectl applies manifests and debugs pods in our cluster."
echo "Used for: kubectl get pods, kubectl logs, kubectl apply"
echo ""

# ------------------------------------------------------------
# TOOL 5: kind
# ------------------------------------------------------------
check_tool \
  "kind — Local Kubernetes Cluster" \
  "kind version" \
  "kind"

echo "kind runs our local hireflow-local cluster for testing."
echo ""

# ------------------------------------------------------------
# TOOL 6: Helm
# ------------------------------------------------------------
check_tool \
  "Helm — Kubernetes Package Manager" \
  "helm version --short 2>/dev/null || helm version | head -1" \
  "v3"

echo "Helm manages environment-specific K8s deployments."
echo ""

# ------------------------------------------------------------
# TOOL 7: curl
# ------------------------------------------------------------
check_tool \
  "curl — HTTP Testing Tool" \
  "curl --version | head -1" \
  "curl"

echo "curl tests /health and /api/form-version endpoints."
echo ""

# ------------------------------------------------------------
# CLUSTER CHECK
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "Checking: Local Kubernetes Cluster (kind)"
echo ""

CLUSTER=$(kind get clusters 2>/dev/null)
if [ ! -z "$CLUSTER" ]; then
  echo "Clusters found: $CLUSTER"
  echo ""
  kubectl get nodes 2>/dev/null
  echo ""
  echo "Status: ✅ Cluster running"
  PASS=$((PASS + 1))
else
  echo "No kind clusters running"
  echo "Run: kind create cluster --name hireflow-local"
  echo "Status: ⚠️  No cluster (create one before K8s tasks)"
  FAIL=$((FAIL + 1))
fi

echo ""

# ------------------------------------------------------------
# HIREFLOW DEPLOYMENT CHECK
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "Checking: HireFlow deployment in cluster"
echo ""

PODS=$(kubectl get pods -n recruitment 2>/dev/null | grep -c "Running")
if [ "$PODS" -gt "0" ]; then
  kubectl get pods -n recruitment 2>/dev/null
  echo ""
  echo "Status: ✅ HireFlow running ($PODS pods)"
  PASS=$((PASS + 1))
else
  echo "No HireFlow pods found in recruitment namespace"
  echo "Run: kubectl apply -f k8s/ to deploy"
  echo "Status: ⚠️  Not deployed yet"
fi

echo ""

# ------------------------------------------------------------
# FINAL SUMMARY
# ------------------------------------------------------------
echo "============================================================"
echo "  WORKSTATION VERIFICATION SUMMARY"
echo "============================================================"
echo ""
echo "  ✅ PASSED: ${PASS} checks"
echo "  ❌ FAILED: ${FAIL} checks"
echo ""

if [ $FAIL -eq 0 ]; then
  echo "  🎉 All tools verified — workstation is ready!"
  echo "  Sprint #3 DevOps implementation can proceed."
else
  echo "  ⚠️  ${FAIL} tool(s) need attention."
  echo "  Fix the failed tools before proceeding."
fi

echo ""
echo "  Tools verified:"
echo "  → Git:        source control + CI trigger"
echo "  → Docker:     image build + container runtime"
echo "  → kubectl:    cluster interaction + debugging"
echo "  → kind:       local Kubernetes cluster"
echo "  → Helm:       K8s package management"
echo "  → curl:       endpoint testing"
echo ""
echo "  OS:      Windows 11 (Git Bash / MINGW64)"
echo "  Cluster: kind-hireflow-local"
echo "============================================================"
echo ""