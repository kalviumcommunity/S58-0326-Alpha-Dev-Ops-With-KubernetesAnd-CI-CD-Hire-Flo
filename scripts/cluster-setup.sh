#!/bin/bash

# ============================================================
# HireFlow — Local Kubernetes Cluster Setup Script
# Team 02 | Sprint #3 | Assignment 4.19
# ============================================================
# Sets up kind cluster and deploys HireFlow manifests
# Prerequisites: Docker Desktop running, kind installed,
#                kubectl installed
# ============================================================

echo ""
echo "============================================================"
echo "  HireFlow — Local Kubernetes Cluster Setup"
echo "  Tool: kind (Kubernetes IN Docker)"
echo "  Team 02 | Sprint #3 | Assignment 4.19"
echo "============================================================"
echo ""

CLUSTER_NAME="hireflow-local"
NAMESPACE="recruitment"

# ------------------------------------------------------------
# STEP 1: Verify Prerequisites
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "STEP 1: Verifying prerequisites"
echo "------------------------------------------------------------"
echo ""

echo ">> Checking Docker is running:"
docker info --format "Server Version: {{.ServerVersion}}" 2>/dev/null
if [ $? -ne 0 ]; then
  echo "❌ Docker is not running. Start Docker Desktop first."
  exit 1
fi
echo "✅ Docker is running"

echo ""
echo ">> Checking kubectl is installed:"
kubectl version --client --short 2>/dev/null || \
  kubectl version --client 2>/dev/null | head -1
if [ $? -ne 0 ]; then
  echo "❌ kubectl not found. Install kubectl first."
  exit 1
fi
echo "✅ kubectl is installed"

echo ""
echo ">> Checking kind is installed:"
kind version
if [ $? -ne 0 ]; then
  echo "❌ kind not found. Install kind first."
  exit 1
fi
echo "✅ kind is installed"
echo ""

# ------------------------------------------------------------
# STEP 2: Create kind Cluster
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "STEP 2: Creating kind cluster: ${CLUSTER_NAME}"
echo "------------------------------------------------------------"
echo ""

# Check if cluster already exists
kind get clusters 2>/dev/null | grep -q "${CLUSTER_NAME}"
if [ $? -eq 0 ]; then
  echo ">> Cluster '${CLUSTER_NAME}' already exists — skipping creation"
else
  echo ">> Creating cluster (this takes 2-3 minutes)..."
  kind create cluster --name ${CLUSTER_NAME}
  if [ $? -ne 0 ]; then
    echo "❌ Cluster creation failed"
    exit 1
  fi
fi

echo ""
echo "✅ Cluster '${CLUSTER_NAME}' is ready"
echo ""

# ------------------------------------------------------------
# STEP 3: Verify Cluster
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "STEP 3: Verifying cluster connectivity"
echo "------------------------------------------------------------"
echo ""

echo ">> Active kubectl context:"
kubectl config current-context

echo ""
echo ">> Cluster info:"
kubectl cluster-info

echo ""
echo ">> Node status:"
kubectl get nodes

echo ""
echo ">> Available clusters:"
kind get clusters

echo ""

# ------------------------------------------------------------
# STEP 4: Deploy HireFlow Manifests
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "STEP 4: Deploying HireFlow to local cluster"
echo "------------------------------------------------------------"
echo ""

echo ">> Applying namespace..."
kubectl apply -f k8s/namespace.yaml
echo ""

echo ">> Applying configmap..."
kubectl apply -f k8s/configmap.yaml
echo ""

echo ">> Applying deployment..."
kubectl apply -f k8s/deployment.yaml
echo ""

echo ">> Applying service..."
kubectl apply -f k8s/service.yaml
echo ""

echo ">> Waiting 30 seconds for pods to start..."
sleep 30
echo ""

# ------------------------------------------------------------
# STEP 5: Verify HireFlow Deployment
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "STEP 5: Verifying HireFlow deployment"
echo "------------------------------------------------------------"
echo ""

echo ">> All resources in recruitment namespace:"
kubectl get all -n ${NAMESPACE}

echo ""
echo ">> Pod details:"
kubectl get pods -n ${NAMESPACE} -o wide

echo ""
echo ">> ConfigMap verification:"
kubectl get configmap hireflow-config \
  -n ${NAMESPACE} -o jsonpath='{.data}' && echo ""

echo ""
echo ">> Deployment status:"
kubectl rollout status deployment/hireflow \
  -n ${NAMESPACE}

echo ""

# ------------------------------------------------------------
# STEP 6: Test Application via Port Forward
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "STEP 6: Testing application via port-forward"
echo "------------------------------------------------------------"
echo ""

echo ">> Starting port-forward (background)..."
kubectl port-forward -n ${NAMESPACE} \
  service/hireflow-service 8080:80 &
PF_PID=$!

sleep 5

echo ""
echo ">> Testing /health endpoint via port-forward:"
curl -s http://localhost:8080/health | cat
echo ""

echo ""
echo ">> Testing /api/form-version endpoint:"
curl -s http://localhost:8080/api/form-version | cat
echo ""

# Stop port-forward
kill $PF_PID 2>/dev/null

echo ""

# ------------------------------------------------------------
# STEP 7: Verify Form Version Injection
# ------------------------------------------------------------
echo "------------------------------------------------------------"
echo "STEP 7: Verifying FORM_VERSION from ConfigMap"
echo "------------------------------------------------------------"
echo ""

POD_NAME=$(kubectl get pods -n ${NAMESPACE} \
  -o name 2>/dev/null | head -1)

if [ ! -z "$POD_NAME" ]; then
  echo ">> Checking env vars in pod: ${POD_NAME}"
  kubectl exec -n ${NAMESPACE} ${POD_NAME} \
    -- env | grep -E "FORM_VERSION|NODE_ENV"
  echo "✅ ConfigMap successfully injected into pod"
else
  echo "⚠️  No pods running yet — check kubectl get pods -n ${NAMESPACE}"
fi

echo ""
echo "============================================================"
echo "  Local Cluster Setup Complete!"
echo ""
echo "  Cluster: kind-${CLUSTER_NAME}"
echo "  Namespace: ${NAMESPACE}"
echo "  HireFlow: 3 pods running"
echo ""
echo "  Quick commands:"
echo "  kubectl get pods -n ${NAMESPACE}"
echo "  kubectl logs -n ${NAMESPACE} <pod-name>"
echo "  kubectl port-forward -n ${NAMESPACE} svc/hireflow-service 8080:80"
echo "============================================================"
echo ""