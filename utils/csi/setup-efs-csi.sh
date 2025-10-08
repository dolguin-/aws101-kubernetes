#!/bin/bash

set -euo pipefail

# EFS CSI Driver Setup Script
# This script installs and configures the AWS EFS CSI Driver

CLUSTER_NAME="${1:-aws101}"
REGION="${2:-us-east-1}"

echo "🚀 Setting up EFS CSI Driver for cluster: ${CLUSTER_NAME}"

# Check if cluster exists
if ! aws eks describe-cluster --name "${CLUSTER_NAME}" --region "${REGION}" >/dev/null 2>&1; then
    echo "❌ Cluster ${CLUSTER_NAME} not found in region ${REGION}"
    exit 1
fi

echo "✅ Cluster ${CLUSTER_NAME} found"

# Get account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "📋 Account ID: ${ACCOUNT_ID}"

# Create IAM policy if it doesn't exist
POLICY_NAME="AmazonEKS_EFS_CSI_Driver_Policy"
POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/${POLICY_NAME}"

if ! aws iam get-policy --policy-arn "${POLICY_ARN}" >/dev/null 2>&1; then
    echo "📝 Creating IAM policy: ${POLICY_NAME}"
    aws iam create-policy \
        --policy-name "${POLICY_NAME}" \
        --policy-document file://iam-policy-example.json
    echo "✅ IAM policy created"
else
    echo "✅ IAM policy already exists"
fi

# Create service account with IAM role
echo "🔐 Creating service account with IAM role..."
eksctl create iamserviceaccount \
    --cluster="${CLUSTER_NAME}" \
    --namespace=kube-system \
    --name=efs-csi-controller-sa \
    --attach-policy-arn="${POLICY_ARN}" \
    --override-existing-serviceaccounts \
    --region="${REGION}" \
    --approve

echo "✅ Service account created"

# Install EFS CSI driver as EKS add-on
echo "📦 Installing EFS CSI driver add-on..."
SERVICE_ACCOUNT_ROLE_ARN=$(aws iam list-roles \
    --query "Roles[?contains(RoleName, 'eksctl-${CLUSTER_NAME}-addon-iamserviceaccount')].Arn" \
    --output text | head -1)

if aws eks create-addon \
    --cluster-name "${CLUSTER_NAME}" \
    --addon-name aws-efs-csi-driver \
    --service-account-role-arn "${SERVICE_ACCOUNT_ROLE_ARN}" \
    --region "${REGION}" >/dev/null 2>&1; then
    echo "✅ EFS CSI driver add-on installed"
else
    echo "⚠️  EFS CSI driver add-on may already exist or failed to install"
fi

# Wait for add-on to be active
echo "⏳ Waiting for add-on to be active..."
aws eks wait addon-active \
    --cluster-name "${CLUSTER_NAME}" \
    --addon-name aws-efs-csi-driver \
    --region "${REGION}"

echo "✅ EFS CSI driver is active"

# Verify installation
echo "🔍 Verifying installation..."
kubectl get pods -n kube-system -l app=efs-csi-controller
kubectl get pods -n kube-system -l app=efs-csi-node

echo "🎯 EFS CSI Driver setup completed successfully!"
echo ""
echo "Next steps:"
echo "1. Create an EFS file system: aws efs create-file-system --tags Key=Name,Value=${CLUSTER_NAME}-efs"
echo "2. Update examples/storageclass.yaml with your EFS ID"
echo "3. Apply examples: kubectl apply -f examples/"
