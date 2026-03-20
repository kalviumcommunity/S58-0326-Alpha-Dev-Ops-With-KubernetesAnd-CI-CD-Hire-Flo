#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

IMAGE="abhich98/hireflow-backend:v2.4.1"
CONTAINER_NAME="hireflow-registry-test"

echo "=== Pulling Docker Image ==="
docker pull $IMAGE

echo -e "\n=== Starting Container ==="
docker run -d \
  --name $CONTAINER_NAME \
  -p 3000:3000 \
  -e FORM_VERSION=v2.4.1 \
  -e NODE_ENV=production \
  $IMAGE

# Give the Node.js server a few seconds to start up
echo "Waiting for server to initialize..."
sleep 5

echo -e "\n=== Testing Health Endpoint ==="
curl -s http://localhost:3000/health
echo ""

echo -e "\n=== Testing Form Version Endpoint ==="
curl -s http://localhost:3000/api/form-version
echo ""

echo -e "\n=== Cleaning Up ==="
docker stop $CONTAINER_NAME
docker rm $CONTAINER_NAME

echo -e "\n=== Workflow Complete! ==="