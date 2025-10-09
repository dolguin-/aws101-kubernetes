#!/bin/bash

# Minikube setup script for aws101-kubernetes course
# Compatible with Kubernetes 1.31

set -euo pipefail

echo "🚀 Starting Minikube cluster for aws101-kubernetes..."

# Check if minikube is installed
if ! command -v minikube &> /dev/null; then
    echo "⚠️  Minikube not found. Installing minikube..."

    # Detect OS and architecture
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)

    case $ARCH in
        x86_64) ARCH="amd64" ;;
        arm64|aarch64) ARCH="arm64" ;;
        *) echo "❌ Unsupported architecture: $ARCH"; exit 1 ;;
    esac

    # Download and install minikube
    MINIKUBE_URL="https://storage.googleapis.com/minikube/releases/latest/minikube-${OS}-${ARCH}"

    echo "📥 Downloading minikube for ${OS}-${ARCH}..."
    if curl -Lo minikube "$MINIKUBE_URL"; then
        chmod +x minikube
        sudo mv minikube /usr/local/bin/
        echo "✅ Minikube installed successfully!"
    else
        echo "❌ Failed to download minikube"
        exit 1
    fi
else
    echo "✅ Minikube is already installed ($(minikube version --short))"
fi

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
