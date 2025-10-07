#!/bin/bash

# Stop minikube cluster

set -euo pipefail

echo "🛑 Stopping Minikube cluster..."

if minikube stop; then
  echo "✅ Minikube cluster stopped successfully!"
else
  echo "❌ Failed to stop Minikube cluster"
  exit 1
fi

echo "💡 Use './minikube-setup.sh' to start again"
