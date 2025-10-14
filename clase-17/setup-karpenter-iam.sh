#!/bin/bash

set -e

ROLE_NAME="KarpenterNodeInstanceRole"
INSTANCE_PROFILE_NAME="KarpenterNodeInstanceProfile"

create_resources() {
    echo "🚀 Configurando IAM para Karpenter..."

    # Crear IAM role
    echo "📝 Creando IAM role $ROLE_NAME..."
    aws iam create-role \
      --role-name $ROLE_NAME \
      --assume-role-policy-document '{
        "Version": "2012-10-17",
        "Statement": [
          {
            "Effect": "Allow",
            "Principal": {
              "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
          }
        ]
      }' || echo "⚠️  Role ya existe"

    # Adjuntar políticas
    echo "🔗 Adjuntando políticas..."
    aws iam attach-role-policy \
      --role-name $ROLE_NAME \
      --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy

    aws iam attach-role-policy \
      --role-name $ROLE_NAME \
      --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy

    aws iam attach-role-policy \
      --role-name $ROLE_NAME \
      --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

    # Crear instance profile
    echo "📋 Creando instance profile..."
    aws iam create-instance-profile \
      --instance-profile-name $INSTANCE_PROFILE_NAME || echo "⚠️  Instance profile ya existe"

    # Asociar role
    echo "🔗 Asociando role al instance profile..."
    aws iam add-role-to-instance-profile \
      --role-name $ROLE_NAME \
      --instance-profile-name $INSTANCE_PROFILE_NAME || echo "⚠️  Role ya asociado"

    echo "✅ Configuración IAM completada!"
}

delete_resources() {
    echo "🗑️  Eliminando recursos IAM de Karpenter..."

    # Remover role del instance profile
    echo "🔗 Removiendo role del instance profile..."
    aws iam remove-role-from-instance-profile \
      --role-name $ROLE_NAME \
      --instance-profile-name $INSTANCE_PROFILE_NAME || echo "⚠️  Role no asociado"

    # Eliminar instance profile
    echo "📋 Eliminando instance profile..."
    aws iam delete-instance-profile \
      --instance-profile-name $INSTANCE_PROFILE_NAME || echo "⚠️  Instance profile no existe"

    # Desadjuntar políticas
    echo "🔗 Desadjuntando políticas..."
    aws iam detach-role-policy \
      --role-name $ROLE_NAME \
      --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy || true

    aws iam detach-role-policy \
      --role-name $ROLE_NAME \
      --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy || true

    aws iam detach-role-policy \
      --role-name $ROLE_NAME \
      --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly || true

    # Eliminar role
    echo "📝 Eliminando IAM role..."
    aws iam delete-role --role-name $ROLE_NAME || echo "⚠️  Role no existe"

    echo "✅ Recursos IAM eliminados!"
}

show_usage() {
    echo "Uso: $0 {create|delete}"
    echo "  create - Crear recursos IAM para Karpenter"
    echo "  delete - Eliminar recursos IAM de Karpenter"
    exit 1
}

case "$1" in
    create)
        create_resources
        ;;
    delete)
        delete_resources
        ;;
    *)
        show_usage
        ;;
esac
