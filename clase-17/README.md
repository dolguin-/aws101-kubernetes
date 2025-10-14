# Escalado de Cluster en Kubernetes

- [Escalado de Cluster en Kubernetes](#escalado-de-cluster-en-kubernetes)
  - [Objetivo de la Clase](#objetivo-de-la-clase)
  - [¿Qué es el Escalado de Cluster?](#qué-es-el-escalado-de-cluster)
  - [Opciones de Escalado](#opciones-de-escalado)
    - [Cluster Autoscaler](#cluster-autoscaler)
    - [Karpenter](#karpenter)
  - [Comparación: Cluster Autoscaler vs Karpenter](#comparación-cluster-autoscaler-vs-karpenter)
  - [Karpenter en Profundidad](#karpenter-en-profundidad)
    - [Arquitectura de Karpenter](#arquitectura-de-karpenter)
    - [Componentes Principales](#componentes-principales)
    - [Ventajas de Karpenter](#ventajas-de-karpenter)
  - [Práctica con Karpenter](#práctica-con-karpenter)
    - [Preparación](#preparación)
    - [Instalación de Karpenter](#instalación-de-karpenter)
    - [Configuración de NodePool](#configuración-de-nodepool)
    - [Configuración de EC2NodeClass](#configuración-de-ec2nodeclass)
    - [Desplegar Aplicación de Prueba](#desplegar-aplicación-de-prueba)
    - [Verificar Escalado](#verificar-escalado)
  - [Comandos útiles](#comandos-útiles)
  - [Troubleshooting](#troubleshooting)
  - [Remover los recursos](#remover-los-recursos)
  - [Disclaimer](#disclaimer)
  - [Referencias](#referencias)
  - [Autor](#autor)

## Objetivo de la Clase

Aprender sobre el **escalado automático de clusters** en Kubernetes, comparando Cluster Autoscaler y Karpenter, con enfoque principal en **Karpenter** como solución moderna y eficiente para el escalado de nodos en AWS EKS.

## ¿Qué es el Escalado de Cluster?

El escalado de cluster se refiere a la capacidad de **agregar o remover nodos** automáticamente según la demanda de recursos. Cuando los pods no pueden ser programados debido a falta de recursos, el sistema debe agregar nuevos nodos. Cuando los nodos están subutilizados, deben ser removidos para optimizar costos.

### Tipos de Escalado en Kubernetes

- **Horizontal Pod Autoscaler (HPA)** - Escala pods basado en métricas
- **Vertical Pod Autoscaler (VPA)** - Ajusta recursos de pods existentes
- **Cluster Autoscaler** - Escala nodos del cluster (tradicional)
- **Karpenter** - Escalado de nodos de nueva generación (AWS)

## Opciones de Escalado

### Cluster Autoscaler

**Cluster Autoscaler** es la solución tradicional de Kubernetes para escalado de nodos:

#### Funcionamiento
- Monitorea pods en estado **Pending** debido a falta de recursos
- Escala **Auto Scaling Groups** (ASG) predefinidos
- Utiliza **launch templates** o **launch configurations**
- Termina nodos subutilizados después de un período de gracia

#### Características
- **Integración nativa** con Kubernetes
- **Soporte multi-cloud** (AWS, GCP, Azure)
- **Configuración** mediante deployment y RBAC
- **Escalado basado en reglas** predefinidas

#### Limitaciones
- Requiere **configuración previa** de ASG para cada tipo de nodo
- **Tiempo de escalado** lento (3-5 minutos)
- **Selección limitada** a instancias predefinidas en ASG
- **Complejidad** en configuración multi-AZ y multi-tipo

### Karpenter

**Karpenter** es una solución moderna desarrollada por AWS:

- **Provisioning directo** de instancias EC2 (sin ASG)
- **Selección inteligente** de tipos de instancia
- **Escalado rápido** - segundos en lugar de minutos
- **Optimización de costos** automática
- **Flexibilidad** en configuración de nodos

## Comparación: Cluster Autoscaler vs Karpenter

| Característica | Cluster Autoscaler | Karpenter |
|---|---|---|
| **Arquitectura** | Basado en ASG | Provisioning directo |
| **Tiempo de escalado** | 3-5 minutos | 15-45 segundos |
| **Selección de instancias** | Predefinida en ASG | Inteligente y automática |
| **Optimización de costos** | Limitada | Avanzada con Spot/On-Demand |
| **Configuración** | Compleja (múltiples ASG) | Simplificada (NodePools) |
| **Flexibilidad** | Baja | Alta |
| **Soporte multi-AZ** | Manual | Automático |
| **Consolidación de nodos** | Básica | Avanzada |
| **Interrupciones Spot** | Manejo básico | Manejo inteligente |
| **Taints y tolerations** | Limitado | Soporte completo |
| **Madurez** | Estable (años) | Estable (desde 2023) |

## Karpenter en Profundidad

### Arquitectura de Karpenter

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Kubernetes    │    │    Karpenter    │    │      AWS        │
│   Scheduler     │    │   Controller    │    │      EC2        │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          │ Pods pendientes      │                      │
          ├─────────────────────►│                      │
          │                      │ Crear instancias    │
          │                      ├─────────────────────►│
          │                      │                      │
          │                      │ Registrar nodos     │
          │◄─────────────────────┤                      │
          │                      │                      │
```

### Componentes Principales

#### NodePool
Define las **especificaciones** de los nodos que Karpenter puede crear:
- Tipos de instancia permitidos
- Arquitecturas (x86, ARM)
- Capacidad (On-Demand, Spot)
- Taints y labels
- Límites de recursos

#### EC2NodeClass
Define la **configuración específica de AWS** para las instancias:
- AMI a utilizar
- Security groups
- Subnets
- Instance profile
- User data
- Block device mappings

### Ventajas de Karpenter

- **Escalado rápido** - Provisioning en segundos
- **Optimización automática** - Selecciona la instancia más eficiente
- **Gestión de Spot** - Manejo inteligente de interrupciones
- **Consolidación** - Optimiza la utilización de nodos
- **Flexibilidad** - Soporte para múltiples tipos de workloads
- **Simplicidad** - Configuración declarativa con CRDs

## Práctica con Karpenter

### Preparación

#### Crear cluster EKS

```bash
# Crear cluster EKS con eksctl (usar configuración del curso)
eksctl create cluster -f ../aws101-cluster.yaml

# O crear cluster básico para Karpenter
eksctl create cluster \
  --name aws101 \
  --region us-east-1 \
  --version 1.34 \
  --nodegroup-name initial-nodes \
  --node-type t3.medium \
  --nodes 1 \
  --nodes-min 1 \
  --nodes-max 3 \
  --with-oidc \
  --managed

# Verificar cluster
kubectl get nodes
```

#### Variables de entorno

```bash
# Configurar variables
export CLUSTER_NAME=aws101  # o aws101 si usas la config del curso
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export TEMPOUT=$(mktemp)

# Verificar configuración
echo "Cluster: $CLUSTER_NAME"
echo "Region: $AWS_DEFAULT_REGION"
echo "Account: $AWS_ACCOUNT_ID"
```

### Instalación de Karpenter

```bash
# Crear namespace
kubectl create namespace karpenter

# Agregar repositorio Helm
# Nota: Karpenter 1.0+ se instala directamente desde OCI

### Instalación de Karpenter

#### Crear IAM Role e Instance Profile

```bash
# Ejecutar script de configuración
./setup-karpenter-iam.sh create

# Para eliminar recursos IAM
./setup-karpenter-iam.sh delete

# O manualmente:
# Crear IAM role para nodos de Karpenter
aws iam create-role \
  --role-name KarpenterNodeInstanceRole \
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
  }'

# Adjuntar políticas necesarias
aws iam attach-role-policy \
  --role-name KarpenterNodeInstanceRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy

aws iam attach-role-policy \
  --role-name KarpenterNodeInstanceRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy

aws iam attach-role-policy \
  --role-name KarpenterNodeInstanceRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

# Crear instance profile
aws iam create-instance-profile \
  --instance-profile-name KarpenterNodeInstanceProfile

# Agregar role al instance profile
aws iam add-role-to-instance-profile \
  --role-name KarpenterNodeInstanceRole \
  --instance-profile-name KarpenterNodeInstanceProfile
```

#### Instalar Karpenter con Helm

# Instalar Karpenter
helm install karpenter oci://public.ecr.aws/karpenter/karpenter \
  --version "1.0.1" \
  --namespace "kube-system" \
  --create-namespace \
  --set "settings.clusterName=${CLUSTER_NAME}" \
  --set controller.resources.requests.cpu=1 \
  --set controller.resources.requests.memory=1Gi \
  --set controller.resources.limits.cpu=1 \
  --set controller.resources.limits.memory=1Gi

# Verificar instalación
kubectl get pods -n kube-system | grep karpenter
kubectl get crd | grep karpenter
```

### Configuración de NodePool

```yaml
# nodepool.yaml
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: default
spec:
  # Template para los nodos
  template:
    metadata:
      labels:
        intent: apps
    spec:
      # Tipos de instancia permitidos
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        - key: kubernetes.io/os
          operator: In
          values: ["linux"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot", "on-demand"]
        - key: node.kubernetes.io/instance-type
          operator: In
          values: ["m5.large", "m5.xlarge", "m5.2xlarge", "c5.large", "c5.xlarge"]

      # Configuración de nodo
      nodeClassRef:
        apiVersion: karpenter.k8s.aws/v1beta1
        kind: EC2NodeClass
        name: default

      # Taints opcionales
      taints:
        - key: example.com/special-workload
          value: "true"
          effect: NoSchedule

  # Límites del NodePool
  limits:
    cpu: 1000
    memory: 1000Gi

  # Configuración de disrupción
  disruption:
    consolidationPolicy: WhenUnderutilized
    consolidateAfter: 30s
    expireAfter: 2160h # 90 días
```

### Configuración de EC2NodeClass

```yaml
# ec2nodeclass.yaml
apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: default
spec:
  # AMI Family
  amiFamily: AL2

  # Subnets (usar las del cluster)
  subnetSelectorTerms:
    - tags:
        alpha.eksctl.io/cluster-name: "${CLUSTER_NAME}"

  # Security Groups
  securityGroupSelectorTerms:
    - tags:
        alpha.eksctl.io/cluster-name: "${CLUSTER_NAME}"

  # Instance Profile
  role: "KarpenterNodeInstanceProfile"

  # User Data
  userData: |
    #!/bin/bash
    /etc/eks/bootstrap.sh ${CLUSTER_NAME}

  # Block Device Mappings
  blockDeviceMappings:
    - deviceName: /dev/xvda
      ebs:
        volumeSize: 20Gi
        volumeType: gp3
        deleteOnTermination: true

  # Tags para las instancias
  tags:
    Name: "Karpenter-${CLUSTER_NAME}"
    Environment: "aws101"
```

### Desplegar Aplicación de Prueba

```yaml
# test-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: inflate
  namespace: default
spec:
  replicas: 0
  selector:
    matchLabels:
      app: inflate
  template:
    metadata:
      labels:
        app: inflate
    spec:
      terminationGracePeriodSeconds: 0
      containers:
        - name: inflate
          image: public.ecr.aws/eks-distro/kubernetes/pause:3.7
          resources:
            requests:
              cpu: 1
              memory: 1.5Gi
      tolerations:
        - key: example.com/special-workload
          operator: Exists
          effect: NoSchedule
```

### Verificar Escalado

```bash
# Aplicar configuraciones
kubectl apply -f nodepool.yaml
kubectl apply -f ec2nodeclass.yaml
kubectl apply -f test-deployment.yaml

# Escalar la aplicación para forzar creación de nodos
kubectl scale deployment inflate --replicas=5

# Verificar nodos creados por Karpenter
kubectl get nodes -l karpenter.sh/provisioner-name
kubectl get nodes --show-labels | grep karpenter

# Ver eventos de Karpenter
kubectl get events -n karpenter --sort-by='.lastTimestamp'

# Verificar pods programados
kubectl get pods -o wide

# Reducir réplicas para ver consolidación
kubectl scale deployment inflate --replicas=1
```

## Comandos útiles

```bash
# Ver NodePools
kubectl get nodepools

# Ver EC2NodeClasses
kubectl get ec2nodeclasses

# Ver nodos gestionados por Karpenter
kubectl get nodes -l karpenter.sh/provisioner-name

# Logs de Karpenter
kubectl logs -f -n kube-system -l app.kubernetes.io/name=karpenter

# Describir NodePool
kubectl describe nodepool default

# Ver métricas de Karpenter
kubectl top nodes

# Forzar consolidación
kubectl annotate nodepool default karpenter.sh/do-not-disrupt-

# Ver eventos del cluster
kubectl get events --sort-by='.lastTimestamp' | grep -i karpenter
```

## Troubleshooting

### Nodos no se crean
```bash
# Verificar logs de Karpenter
kubectl logs -n kube-system -l app.kubernetes.io/name=karpenter

# Verificar permisos IAM
aws sts get-caller-identity

# Verificar configuración de subnets
kubectl describe ec2nodeclass default

# Verificar pods pendientes
kubectl get pods --field-selector=status.phase=Pending
```

### Nodos no se terminan
```bash
# Verificar política de consolidación
kubectl describe nodepool default

# Forzar consolidación
kubectl patch nodepool default --type merge -p '{"spec":{"disruption":{"consolidateAfter":"10s"}}}'

# Ver nodos marcados para terminación
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.annotations.karpenter\.sh/do-not-disrupt}{"\n"}{end}'
```

### Problemas de permisos
```bash
# Verificar service account
kubectl get sa -n karpenter

# Verificar IAM role
aws iam get-role --role-name KarpenterControllerRole-${CLUSTER_NAME}

# Verificar instance profile
aws iam get-instance-profile --instance-profile-name KarpenterNodeInstanceProfile
```

## Remover los recursos

```bash
# Eliminar aplicación de prueba
kubectl delete deployment inflate

# Esperar a que Karpenter termine los nodos
kubectl get nodes -w

# Desinstalar Karpenter
helm uninstall karpenter -n kube-system

# Eliminar CRDs
kubectl delete crd nodepools.karpenter.sh
kubectl delete crd ec2nodeclasses.karpenter.k8s.aws

# Eliminar IAM resources
aws iam remove-role-from-instance-profile \
  --role-name KarpenterNodeInstanceRole \
  --instance-profile-name KarpenterNodeInstanceProfile

aws iam delete-instance-profile \
  --instance-profile-name KarpenterNodeInstanceProfile

aws iam detach-role-policy \
  --role-name KarpenterNodeInstanceRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy

aws iam detach-role-policy \
  --role-name KarpenterNodeInstanceRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy

aws iam detach-role-policy \
  --role-name KarpenterNodeInstanceRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

aws iam delete-role \
  --role-name KarpenterNodeInstanceRole

# Eliminar cluster EKS completo
eksctl delete cluster --name $CLUSTER_NAME --region $AWS_DEFAULT_REGION

# Verificar que todos los recursos AWS fueron eliminados
aws ec2 describe-instances --filters "Name=tag:kubernetes.io/cluster/$CLUSTER_NAME,Values=owned" --query 'Reservations[].Instances[].InstanceId'
```

## Disclaimer

El participante es 100% responsable de los costos generados al realizar las prácticas. Desde este espacio renunciamos a toda responsabilidad por costos generados al realizar los laboratorios.

Les pedimos que sean conscientes de remover todos los recursos utilizados cuando finalicen las prácticas.

## Referencias

- [Karpenter Documentation](https://karpenter.sh/)
- [AWS Karpenter Workshop](https://www.eksworkshop.com/docs/autoscaling/compute/karpenter/)
- [Cluster Autoscaler Documentation](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)
- [EKS Best Practices - Autoscaling](https://aws.github.io/aws-eks-best-practices/cluster-autoscaling/)

## Autor

**Damian A. Gitto Olguin**
[AWS Community Hero](https://www.youtube.com/c/damianolguinAWSHERO)
[@enlink](https://twitter.com/enlink) / [@teracloudio](https://twitter.com/teracloudio)
<https://teracloud.io>
