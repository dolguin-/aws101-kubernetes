#!/bin/bash

set -euo pipefail

echo "🔧 Installing MetalLB Load Balancer..."

# Install MetalLB using the latest stable version
echo "📦 Applying MetalLB manifests..."
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.8/config/manifests/metallb-native.yaml

# Wait for MetalLB to be ready
echo "⏳ Waiting for MetalLB pods to be ready..."
kubectl wait --namespace metallb-system \
    --for=condition=ready pod \
    --selector=app=metallb \
    --timeout=90s

# Get Docker network CIDR for kind
echo "🔍 Detecting Docker network configuration..."
NETWORK_CIDR=$(docker network inspect -f '{{range .IPAM.Config}}{{.Subnet}}{{end}}' kind)
echo "📡 Docker network CIDR: ${NETWORK_CIDR}"

# Calculate IP range for MetalLB (using last 50 IPs of the subnet)
if [[ "${NETWORK_CIDR}" == "172.18.0.0/16" ]]; then
    IP_RANGE="172.18.255.200-172.18.255.250"
elif [[ "${NETWORK_CIDR}" == "172.19.0.0/16" ]]; then
    IP_RANGE="172.19.255.200-172.19.255.250"
else
    echo "⚠️  Unknown network CIDR: ${NETWORK_CIDR}"
    echo "📝 Please manually configure MetalLB IP range"
    exit 1
fi

echo "🎯 Using IP range: ${IP_RANGE}"

# Create MetalLB configuration
cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: example
  namespace: metallb-system
spec:
  addresses:
  - ${IP_RANGE}
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: empty
  namespace: metallb-system
EOF

echo "✅ MetalLB installation completed successfully!"
echo "🌐 LoadBalancer services will use IP range: ${IP_RANGE}"
