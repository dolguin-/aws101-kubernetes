# Amazon EFS Helper Script

## Introducción

Este script automatiza la creación y configuración de Amazon Elastic File System (EFS) en el mismo VPC donde reside el cluster EKS. EFS proporciona almacenamiento de archivos completamente administrado y escalable para usar con Kubernetes.

## Requisitos

- Cluster EKS funcionando
- AWS CLI configurado con permisos apropiados
- jq instalado para procesamiento JSON
- Permisos IAM para EFS, EC2 y VPC

## Permisos IAM requeridos

El usuario/role debe tener los siguientes permisos:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:CreateSecurityGroup",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:DeleteSecurityGroup",
        "efs:CreateFileSystem",
        "efs:DescribeFileSystems",
        "efs:CreateMountTarget",
        "efs:DescribeMountTargets",
        "efs:DeleteMountTarget",
        "efs:DeleteFileSystem"
      ],
      "Resource": "*"
    }
  ]
}
```

## Uso

### Crear EFS File System

```bash
./create-efs.sh -c CLUSTER_NAME
```

**Ejemplo:**
```bash
./create-efs.sh -c aws101
```

### Eliminar EFS File System

```bash
./create-efs.sh -d CLUSTER_NAME
```

**Ejemplo:**
```bash
./create-efs.sh -d aws101
```

## ¿Qué hace el script?

### Al crear (`-c`):

1. **Obtiene información del cluster**
   - VPC ID del cluster EKS
   - CIDR range de la VPC
   - Subnets disponibles

2. **Configura seguridad**
   - Crea security group específico para EFS
   - Configura reglas de ingress para puerto 2049 (NFS)

3. **Crea EFS file system**
   - File system encriptado
   - Etiquetado con nombre del cluster
   - Configuración de rendimiento optimizada

4. **Crea mount targets**
   - Mount target en cada subnet del cluster
   - Asocia security group apropiado

### Al eliminar (`-d`):

1. **Elimina mount targets**
   - Encuentra todos los mount targets del file system
   - Los elimina de forma segura

2. **Elimina file system**
   - Elimina el EFS file system completamente

3. **Limpia recursos**
   - Elimina security group asociado

## Configuración resultante

Después de ejecutar el script, tendrás:

- **EFS File System** encriptado y listo para usar
- **Mount Targets** en todas las subnets del cluster
- **Security Group** configurado para acceso NFS
- **Etiquetas** apropiadas para identificación

## Uso con Kubernetes

### 1. Instalar EFS CSI Driver

```bash
# Ver documentación en utils/csi/
kubectl apply -k "github.com/kubernetes-sigs/aws-efs-csi-driver/deploy/kubernetes/overlays/stable/?ref=release-1.7"
```

### 2. Crear StorageClass

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-sc
provisioner: efs.csi.aws.com
parameters:
  provisioningMode: efs-ap
  fileSystemId: fs-xxxxxxxxx  # ID del EFS creado
  directoryPerms: "0755"
```

### 3. Crear PVC

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

### 4. Usar en Pod

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
    - name: efs-storage
      mountPath: /mnt/efs
  volumes:
  - name: efs-storage
    persistentVolumeClaim:
      claimName: efs-claim
```

## Verificación

### Comprobar EFS file system

```bash
# Listar file systems
aws efs describe-file-systems --query "FileSystems[?Tags[?Key=='Name' && Value=='CLUSTER_NAMEVolume']]"

# Verificar mount targets
aws efs describe-mount-targets --file-system-id fs-xxxxxxxxx
```

### Probar conectividad

```bash
# Desde un pod en el cluster
kubectl run -it --rm debug --image=busybox --restart=Never -- sh

# Dentro del pod
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,intr,timeo=600 \
  fs-xxxxxxxxx.efs.REGION.amazonaws.com:/ /mnt/efs
```

## Troubleshooting

### Problemas comunes

#### 1. Error de permisos

```bash
# Verificar permisos AWS
aws sts get-caller-identity
aws iam get-user
```

#### 2. Mount targets no se crean

```bash
# Verificar subnets del cluster
aws eks describe-cluster --name CLUSTER_NAME --query "cluster.resourcesVpcConfig.subnetIds"

# Verificar security groups
aws ec2 describe-security-groups --filters "Name=group-name,Values=CLUSTER_NAMEVolume"
```

#### 3. No se puede montar en pods

```bash
# Verificar EFS CSI driver
kubectl get pods -n kube-system -l app=efs-csi-controller

# Verificar logs
kubectl logs -n kube-system -l app=efs-csi-controller
```

### Logs del script

El script proporciona salida detallada de cada paso:

```bash
VPC ID: vpc-xxxxxxxxx
CIDR: 10.0.0.0/16
Security Group id: sg-xxxxxxxxx
EFS Security Group Rule id: sgr-xxxxxxxxx
Volumen EFS: fs-xxxxxxxxx
Mount target - Subnetid=subnet-xxxxxxxxx Mount_target_id=fsmt-xxxxxxxxx
```

## Costos

### Factores de costo de EFS:

- **Almacenamiento estándar**: $0.30 por GB/mes
- **Almacenamiento IA**: $0.045 por GB/mes (acceso poco frecuente)
- **Throughput provisionado**: $6.00 por MB/s/mes
- **Requests**: $0.0004 por 1000 requests

### Optimización de costos:

1. **Usar Lifecycle Management** para mover archivos a IA
2. **Monitorear métricas** de CloudWatch
3. **Eliminar file systems** no utilizados

## Mejores Prácticas

### Seguridad

- Habilitar **encryption at rest** (incluido en el script)
- Usar **encryption in transit** en mount options
- Implementar **Access Points** para control granular
- Configurar **VPC endpoints** para tráfico privado

### Rendimiento

- Usar **Provisioned Throughput** para cargas intensivas
- Configurar **Max I/O mode** para alta concurrencia
- Optimizar **mount options** según caso de uso

### Monitoreo

- Configurar **CloudWatch alarms** para métricas EFS
- Monitorear **TotalIOBytes** y **ClientConnections**
- Usar **AWS Config** para compliance

## Referencias

- [Amazon EFS Documentation](https://docs.aws.amazon.com/efs/)
- [EFS CSI Driver](https://github.com/kubernetes-sigs/aws-efs-csi-driver)
- [EFS Performance](https://docs.aws.amazon.com/efs/latest/ug/performance.html)

## Disclaimer

El participante es 100% responsable de los costos generados al realizar las prácticas. Desde este espacio renunciamos a toda responsabilidad por costos generados al realizar los laboratorios.

Les pedimos que sean conscientes de remover todos los recursos utilizados cuando finalicen las prácticas.

## Autor

Damian A. Gitto Olguin
[AWS Community Hero](https://www.youtube.com/c/damianolguinAWSHERO)
[@enlink](https://twitter.com/enlink) / [@teracloudio](https://twitter.com/teracloudio)
<https://teracloud.io>
