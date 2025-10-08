# Amazon EFS CSI Driver

## Introducción

El Amazon EFS CSI Driver permite que los pods de Kubernetes utilicen Amazon Elastic File System (EFS) como almacenamiento persistente. EFS proporciona almacenamiento compartido escalable y completamente administrado.

## Requisitos

- Cluster EKS funcionando
- Amazon EFS file system creado
- Permisos IAM configurados
- EFS CSI Driver instalado en el cluster

## Instalación del CSI Driver

### Opción 1: EKS Add-on (Recomendado)

```bash
# Crear IAM role para el CSI driver
eksctl create iamserviceaccount \
  --cluster=aws101 \
  --namespace=kube-system \
  --name=efs-csi-controller-sa \
  --attach-policy-arn=arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy \
  --override-existing-serviceaccounts \
  --approve

# Instalar EFS CSI driver como add-on
aws eks create-addon \
  --cluster-name aws101 \
  --addon-name aws-efs-csi-driver \
  --service-account-role-arn arn:aws:iam::ACCOUNT_ID:role/AmazonEKS_EFS_CSI_DriverRole
```

### Opción 2: Helm

```bash
# Agregar repositorio de Helm
helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/
helm repo update

# Instalar driver
helm upgrade --install aws-efs-csi-driver \
  --namespace kube-system \
  aws-efs-csi-driver/aws-efs-csi-driver
```

### Opción 3: Manifiestos YAML

```bash
kubectl apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.7"
```

## Configuración IAM

### Crear IAM Policy personalizada

```bash
# Usar la policy incluida en este directorio
aws iam create-policy \
  --policy-name AmazonEKS_EFS_CSI_Driver_Policy \
  --policy-document file://iam-policy-example.json
```

### Asociar policy al Service Account

```bash
# Obtener ARN de la policy
POLICY_ARN=$(aws iam list-policies \
  --query 'Policies[?PolicyName==`AmazonEKS_EFS_CSI_Driver_Policy`].Arn' \
  --output text)

# Crear service account con la policy
eksctl create iamserviceaccount \
  --cluster=aws101 \
  --namespace=kube-system \
  --name=efs-csi-controller-sa \
  --attach-policy-arn=$POLICY_ARN \
  --override-existing-serviceaccounts \
  --approve
```

## Crear EFS File System

### Usando AWS CLI

```bash
# Obtener VPC ID del cluster
VPC_ID=$(aws eks describe-cluster \
  --name aws101 \
  --query "cluster.resourcesVpcConfig.vpcId" \
  --output text)

# Crear EFS file system
EFS_ID=$(aws efs create-file-system \
  --performance-mode generalPurpose \
  --throughput-mode provisioned \
  --provisioned-throughput-in-mibps 100 \
  --encrypted \
  --tags Key=Name,Value=aws101-efs \
  --query 'FileSystemId' \
  --output text)

echo "EFS ID: $EFS_ID"
```

### Crear Mount Targets

```bash
# Obtener subnets del cluster
SUBNET_IDS=$(aws eks describe-cluster \
  --name aws101 \
  --query "cluster.resourcesVpcConfig.subnetIds" \
  --output text)

# Crear security group para EFS
SG_ID=$(aws ec2 create-security-group \
  --group-name efs-mount-target-sg \
  --description "Security group for EFS mount targets" \
  --vpc-id $VPC_ID \
  --query 'GroupId' \
  --output text)

# Permitir tráfico NFS
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 2049 \
  --source-group $SG_ID

# Crear mount targets
for subnet in $SUBNET_IDS; do
  aws efs create-mount-target \
    --file-system-id $EFS_ID \
    --subnet-id $subnet \
    --security-groups $SG_ID
done
```

## Uso con Kubernetes

### StorageClass

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: fs-xxxxxxxxx
  directoryPerms: "0755"
  gidRangeStart: "1000"
  gidRangeEnd: "2000"
  basePath: "/dynamic_provisioning"
```

### PersistentVolume estático

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: efs-pv
spec:
  capacity:
    storage: 5Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: efs-sc
  csi:
    driver: efs.csi.aws.com
    volumeHandle: fs-xxxxxxxxx
```

### PersistentVolumeClaim

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: efs-claim
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: efs-sc
  resources:
    requests:
      storage: 5Gi
```

### Pod usando EFS

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: efs-app
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: persistent-storage
      mountPath: /usr/share/nginx/html
  volumes:
  - name: persistent-storage
    persistentVolumeClaim:
      claimName: efs-claim
```

## Ejemplos Avanzados

### Deployment con EFS compartido

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: shared-storage-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: shared-app
  template:
    metadata:
      labels:
        app: shared-app
    spec:
      containers:
      - name: app
        image: nginx
        volumeMounts:
        - name: shared-data
          mountPath: /shared
      volumes:
      - name: shared-data
        persistentVolumeClaim:
          claimName: efs-claim
```

### StatefulSet con EFS

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: efs-statefulset
spec:
  serviceName: efs-service
  replicas: 2
  selector:
    matchLabels:
      app: efs-app
  template:
    metadata:
      labels:
        app: efs-app
    spec:
      containers:
      - name: app
        image: nginx
        volumeMounts:
        - name: efs-storage
          mountPath: /data
  volumeClaimTemplates:
  - metadata:
      name: efs-storage
    spec:
      accessModes: ["ReadWriteMany"]
      storageClassName: efs-sc
      resources:
        requests:
          storage: 1Gi
```

## Verificación

### Comprobar instalación del driver

```bash
# Verificar pods del CSI driver
kubectl get pods -n kube-system -l app=efs-csi-controller
kubectl get pods -n kube-system -l app=efs-csi-node

# Verificar CSI driver
kubectl get csidriver efs.csi.aws.com
```

### Probar funcionalidad

```bash
# Aplicar manifiestos de prueba
kubectl apply -f examples/

# Verificar PVC
kubectl get pvc efs-claim

# Verificar montaje en pod
kubectl exec -it efs-app -- df -h /usr/share/nginx/html
```

## Troubleshooting

### Problemas comunes

#### 1. Mount targets no disponibles

```bash
# Verificar mount targets
aws efs describe-mount-targets --file-system-id fs-xxxxxxxxx

# Verificar security groups
aws ec2 describe-security-groups --group-ids sg-xxxxxxxxx
```

#### 2. Permisos IAM insuficientes

```bash
# Verificar service account
kubectl describe sa efs-csi-controller-sa -n kube-system

# Verificar annotations del SA
kubectl get sa efs-csi-controller-sa -n kube-system -o yaml
```

#### 3. Pod no puede montar volumen

```bash
# Verificar eventos del pod
kubectl describe pod efs-app

# Verificar logs del CSI driver
kubectl logs -n kube-system -l app=efs-csi-controller
```

### Logs útiles

```bash
# Logs del controller
kubectl logs -n kube-system deployment/efs-csi-controller

# Logs de los nodos
kubectl logs -n kube-system daemonset/efs-csi-node
```

## Mejores Prácticas

### Rendimiento

- Usar **Provisioned Throughput** para cargas de trabajo intensivas
- Configurar **Max I/O mode** para alta concurrencia
- Usar **Regional** mount targets para alta disponibilidad

### Seguridad

- Habilitar **encryption at rest** y **in transit**
- Usar **Access Points** para control granular
- Implementar **least privilege** en IAM policies

### Costos

- Monitorear uso con **CloudWatch metrics**
- Usar **Infrequent Access** para datos poco utilizados
- Configurar **Lifecycle policies** apropiadas

## Referencias

- [AWS EFS CSI Driver](https://github.com/kubernetes-sigs/aws-efs-csi-driver)
- [Amazon EFS Documentation](https://docs.aws.amazon.com/efs/)
- [EKS Storage Classes](https://docs.aws.amazon.com/eks/latest/userguide/storage-classes.html)

## Autor

Damian A. Gitto Olguin
[AWS Community Hero](https://www.youtube.com/c/damianolguinAWSHERO)
[@enlink](https://twitter.com/enlink) / [@teracloudio](https://twitter.com/teracloudio)
<https://teracloud.io>
