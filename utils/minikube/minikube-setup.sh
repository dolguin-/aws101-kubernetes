#!/bin/bash

# Minikube setup script for aws101-kubernetes course
# Compatible with Kubernetes 1.31

set -euo pipefail

echo "🚀 Starting Minikube cluster for aws101-kubernetes..."

# Start minikube with specific configuration
if minikube start \
  --kubernetes-version=v1.31.0 \
  --driver=docker \
  --cpus=2 \
  --memory=4096 \
  --disk-size=20g \
  --addons=ingress,dashboard,metrics-server; then
  echo "✅ Minikube cluster started successfully!"
else
  echo "❌ Failed to start Minikube cluster"
  exit 1
fi

# Enable required addons
echo "🔧 Enabling additional addons..."
minikube addons enable ingress-dns
minikube addons enable storage-provisioner

# Display cluster info
echo "📊 Cluster Information:"
kubectl cluster-info
kubectl get nodes

echo "🎯 Ready to run aws101-kubernetes exercises!"
echo "💡 Use 'kubectl get namespaces' to see available namespaces"
echo "🌐 Access dashboard with: minikube dashboard"
