# External Secrets Operator

- [External Secrets Operator](#external-secrets-operator)
  - [Objetivo de la Clase](#objetivo-de-la-clase)
  - [¿Qué es External Secrets Operator?](#qué-es-external-secrets-operator)
  - [¿Por qué usar External Secrets?](#por-qué-usar-external-secrets)
  - [Arquitectura y Componentes](#arquitectura-y-componentes)
    - [SecretStore vs ClusterSecretStore](#secretstore-vs-clustersecretstore)
    - [ExternalSecret](#externalsecret)
    - [Backends Soportados](#backends-soportados)
  - [Instalación](#instalación)
  - [Configuración con AWS](#configuración-con-aws)
    - [AWS Secrets Manager](#aws-secrets-manager)
    - [AWS SSM Parameter Store](#aws-ssm-parameter-store)
    - [Configuración IAM](#configuración-iam)
  - [Práctica](#práctica)
    - [Preparación](#preparación)
    - [Configurar Backend AWS](#configurar-backend-aws)
    - [Crear SecretStore](#crear-secretstore)
    - [Crear ExternalSecret](#crear-externalsecret)
    - [Verificar Sincronización](#verificar-sincronización)
  - [Otros Backends](#otros-backends)
  - [Comandos útiles](#comandos-útiles)
  - [Troubleshooting](#troubleshooting)
  - [Remover los recursos](#remover-los-recursos)
  - [Disclaimer](#disclaimer)
  - [Referencias](#referencias)
  - [Autor](#autor)

## Objetivo de la Clase

Dominar la **administración avanzada de secretos en Kubernetes** utilizando External Secrets Operator (ESO) para integrar sistemas externos de gestión de secretos, automatizando la sincronización y rotación de secretos desde múltiples backends de forma segura y escalable.

Esta clase es la evolución natural de los conceptos básicos aprendidos en la [**Clase 8 - Secretos**](../clase-8/), donde vimos cómo crear y gestionar secretos nativos de Kubernetes. Ahora avanzaremos hacia soluciones empresariales que resuelven las limitaciones de la gestión manual.

## ¿Qué es External Secrets Operator?

**External Secrets Operator (ESO)** es un operador de Kubernetes que sincroniza secretos desde sistemas externos hacia secretos nativos de Kubernetes. Actúa como un puente entre tu cluster y proveedores de secretos externos, manteniendo los secretos actualizados automáticamente.

### Características Principales

- **Sincronización automática** de secretos desde múltiples backends
- **Rotación automática** cuando los secretos cambian en el origen
- **Múltiples proveedores** soportados (AWS, Azure, GCP, Vault, etc.)
- **Configuración declarativa** usando Custom Resources
- **Seguridad mejorada** - secretos nunca en código o manifiestos
- **Escalabilidad** - maneja miles de secretos eficientemente

## ¿Por qué usar External Secrets?

### Evolución desde Secretos Básicos

En la [**Clase 8 - Secretos**](../clase-8/) aprendimos los fundamentos de la gestión de secretos en Kubernetes: cómo crear, usar y gestionar secretos nativos. Estos conocimientos son la base esencial, pero en entornos de producción y empresariales necesitamos **administración avanzada de secretos**.

### Limitaciones de la Gestión Manual

Los secretos nativos de Kubernetes, aunque útiles para casos básicos, presentan desafíos significativos en producción:

- ❌ **Gestión manual** - Crear y actualizar secretos manualmente
- ❌ **Sin rotación automática** - Cambios requieren intervención manual
- ❌ **Falta de auditoría** - Difícil rastrear accesos y cambios
- ❌ **Almacenamiento local** - Secretos en etcd del cluster
- ❌ **Sin versionado** - No hay historial de cambios
- ❌ **Escalabilidad limitada** - Difícil gestionar cientos de secretos
- ❌ **Compliance** - No cumple estándares empresariales

### ¿Por qué External Secrets Operator?

La **administración avanzada de secretos en Kubernetes** requiere herramientas especializadas que integren con sistemas externos empresariales:

- ✅ **Gestión centralizada** - Un solo lugar para todos los secretos
- ✅ **Rotación automática** - Secretos se actualizan automáticamente
- ✅ **Auditoría completa** - Logs detallados de todos los accesos
- ✅ **Múltiples backends** - Flexibilidad en la elección de proveedor
- ✅ **Versionado** - Historial completo de cambios
- ✅ **Escalabilidad** - Maneja miles de secretos eficientemente
- ✅ **Compliance** - Cumple estándares empresariales
- ✅ **Separación de responsabilidades** - Equipos de seguridad gestionan secretos centralmente

## Arquitectura y Componentes

### SecretStore vs ClusterSecretStore

**SecretStore**
- Configuración de backend a **nivel de namespace**
- Secretos accesibles solo dentro del namespace
- Ideal para equipos o aplicaciones específicas

**ClusterSecretStore**
- Configuración **global** para todo el cluster
- Secretos accesibles desde cualquier namespace
- Ideal para configuraciones compartidas

### ExternalSecret

Un **ExternalSecret** define:
- **Qué secretos** obtener del backend externo
- **Cómo mapear** los datos a un Secret de Kubernetes
- **Cuándo actualizar** (refresh interval)
- **Dónde crear** el Secret resultante

### Backends Soportados

- **AWS**:
  - Secrets Manager
  - SSM Parameter Store
- **HashiCorp Vault**:
  - KV v1/v2
  - Database
  - PKI
- **Azure**:
  - Key Vault
- **Google Cloud**:
  - Secret Manager
- **Kubernetes**:
  - Secretos de otros clusters
- **Otros**:
  - GitLab
  - Doppler
  - 1Password
  - Y muchos más

## Instalación

### Instalar External Secrets Operator

```bash
# Agregar repositorio de Helm
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

# Instalar ESO
helm install external-secrets external-secrets/external-secrets \
  --namespace external-secrets-system \
  --create-namespace

# Verificar instalación
kubectl get pods -n external-secrets-system
```

## Configuración con AWS

### AWS Secrets Manager

**Características:**
- Rotación automática nativa
- Integración con RDS/DocumentDB
- Encriptación siempre activa
- Ideal para secretos críticos

**Casos de uso:** Credenciales de bases de datos, API keys críticos, certificados

### AWS SSM Parameter Store

**Características:**
- Más económico que Secrets Manager
- Soporte para jerarquías
- Encriptación opcional con KMS
- Ideal para configuración general

**Casos de uso:** Configuración de aplicaciones, parámetros no críticos

| Característica | Secrets Manager | Parameter Store |
|---|---|---|
| **Costo** | Más caro | Más económico |
| **Rotación automática** | ✅ Nativa | ❌ Manual |
| **Límite de tamaño** | 64KB | 8KB |
| **Encriptación** | ✅ Siempre | ✅ Opcional |
| **Casos de uso** | Secretos críticos | Configuración general |

### Configuración IAM

```bash
# Crear policy IAM
cat > iam-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret",
                "ssm:GetParameter",
                "ssm:GetParameters",
                "ssm:GetParametersByPath"
            ],
            "Resource": [
                "arn:aws:secretsmanager:*:*:secret:clase15/*",
                "arn:aws:ssm:*:*:parameter/clase15/*"
            ]
        }
    ]
}
EOF

# Crear policy
aws iam create-policy \
  --policy-name ExternalSecretsPolicy \
  --policy-document file://iam-policy.json

# Crear service account con IRSA (EKS)
eksctl create iamserviceaccount \
  --name external-secrets-sa \
  --namespace clase15 \
  --cluster tu-cluster-name \
  --attach-policy-arn arn:aws:iam::ACCOUNT-ID:policy/ExternalSecretsPolicy \
  --approve
```

## Práctica

### Preparación

```bash
# Crear namespace
kubectl create namespace clase15
```

### Configurar Backend AWS

#### Opción A: AWS Secrets Manager
```bash
# Crear secreto
aws secretsmanager create-secret \
  --name "clase15/database-credentials" \
  --secret-string '{"username":"admin","password":"mi-password-secreto","host":"db.ejemplo.com","port":"5432"}'
```

#### Opción B: AWS SSM Parameter Store
```bash
# Crear parámetros
aws ssm put-parameter --name "/clase15/database/username" --value "admin" --type "String"
aws ssm put-parameter --name "/clase15/database/password" --value "mi-password-secreto" --type "SecureString"
aws ssm put-parameter --name "/clase15/database/host" --value "db.ejemplo.com" --type "String"
aws ssm put-parameter --name "/clase15/database/port" --value "5432" --type "String"
```

### Crear SecretStore

#### Para Secrets Manager
```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets-manager
  namespace: clase15
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        serviceAccount:
          name: external-secrets-sa
```

#### Para Parameter Store
```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-parameter-store
  namespace: clase15
spec:
  provider:
    aws:
      service: ParameterStore
      region: us-east-1
      auth:
        serviceAccount:
          name: external-secrets-sa
```

### Crear ExternalSecret

#### Para Secrets Manager
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-secret
  namespace: clase15
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: database-credentials
    creationPolicy: Owner
  data:
  - secretKey: username
    remoteRef:
      key: clase15/database-credentials
      property: username
  - secretKey: password
    remoteRef:
      key: clase15/database-credentials
      property: password
```

#### Para Parameter Store
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-secret-ssm
  namespace: clase15
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-parameter-store
    kind: SecretStore
  target:
    name: database-credentials-ssm
    creationPolicy: Owner
  data:
  - secretKey: username
    remoteRef:
      key: /clase15/database/username
  - secretKey: password
    remoteRef:
      key: /clase15/database/password
```

### Verificar Sincronización

```bash
# Verificar ExternalSecret
kubectl get externalsecret -n clase15

# Verificar Secret creado
kubectl get secret -n clase15

# Ver contenido del secret
kubectl get secret database-credentials -n clase15 -o jsonpath='{.data.username}' | base64 -d
```

## Otros Backends

### HashiCorp Vault
```yaml
spec:
  provider:
    vault:
      server: "https://vault.ejemplo.com"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "external-secrets"
```

### Azure Key Vault
```yaml
spec:
  provider:
    azurekv:
      vaultUrl: "https://mi-vault.vault.azure.net/"
      authType: ServicePrincipal
      clientId: "client-id"
      clientSecret:
        secretRef:
          name: azure-secret
          key: client-secret
```

### Google Secret Manager
```yaml
spec:
  provider:
    gcpsm:
      projectId: "mi-proyecto-gcp"
      auth:
        workloadIdentity:
          clusterLocation: us-central1
          clusterName: mi-cluster
          serviceAccountRef:
            name: external-secrets-sa
```

## Comandos útiles

```bash
# Listar ExternalSecrets
kubectl get externalsecret -A

# Ver estado detallado
kubectl describe externalsecret database-secret -n clase15

# Forzar sincronización
kubectl annotate externalsecret database-secret -n clase15 force-sync=$(date +%s)

# Ver logs del operator
kubectl logs -n external-secrets-system -l app.kubernetes.io/name=external-secrets

# Verificar SecretStore
kubectl get secretstore -n clase15

# Listar secretos gestionados por ESO
kubectl get secret -n clase15 -l managed-by=external-secrets
```

## Troubleshooting

### Problemas Comunes

#### ExternalSecret en estado "SecretSyncError"
```bash
# Verificar logs del operator
kubectl logs -n external-secrets-system deployment/external-secrets

# Verificar configuración del SecretStore
kubectl describe secretstore aws-secrets-manager -n clase15

# Verificar permisos IAM
aws sts get-caller-identity
```

#### Secret no se actualiza automáticamente
```bash
# Verificar refreshInterval
kubectl get externalsecret database-secret -n clase15 -o yaml | grep refreshInterval

# Forzar sincronización manual
kubectl annotate externalsecret database-secret -n clase15 force-sync=$(date +%s)
```

#### Errores de autenticación AWS
```bash
# Verificar service account
kubectl get sa external-secrets-sa -n clase15 -o yaml

# Verificar anotaciones IRSA
kubectl get sa external-secrets-sa -n clase15 -o jsonpath='{.metadata.annotations}'
```

## Remover los recursos

Para limpiar todos los recursos creados:

```bash
# Eliminar ExternalSecret y SecretStore
kubectl delete externalsecret database-secret -n clase15
kubectl delete secretstore aws-secrets-manager -n clase15

# Eliminar secreto de AWS Secrets Manager
aws secretsmanager delete-secret --secret-id "clase15/database-credentials" --force-delete-without-recovery

# O eliminar parámetros de SSM Parameter Store
aws ssm delete-parameter --name "/clase15/database/username"
aws ssm delete-parameter --name "/clase15/database/password"
aws ssm delete-parameter --name "/clase15/database/host"
aws ssm delete-parameter --name "/clase15/database/port"

# Desinstalar External Secrets Operator
helm uninstall external-secrets -n external-secrets-system

# Eliminar namespaces
kubectl delete namespace clase15
kubectl delete namespace external-secrets-system

# Limpiar IAM (opcional)
aws iam delete-policy --policy-arn arn:aws:iam::ACCOUNT-ID:policy/ExternalSecretsPolicy
```

## Disclaimer

El participante es 100% responsable de los costos generados al realizar las prácticas. Desde este espacio renunciamos a toda responsabilidad por costos generados al realizar los laboratorios.

Les pedimos que sean conscientes de remover todos los recursos utilizados cuando finalicen las prácticas.

## Referencias

- [External Secrets Operator Documentation](https://external-secrets.io/)
- [AWS Secrets Manager Documentation](https://docs.aws.amazon.com/secretsmanager/)
- [Clase 8 - Secretos en Kubernetes](../clase-8/)
- [External Secrets Operator GitHub](https://github.com/external-secrets/external-secrets)
- [AWS IAM Roles for Service Accounts (IRSA)](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)

## Autor

**Damian A. Gitto Olguin**
[AWS Community Hero](https://www.youtube.com/c/damianolguinAWSHERO)
[@enlink](https://twitter.com/enlink) / [@teracloudio](https://twitter.com/teracloudio)
<https://teracloud.io>
