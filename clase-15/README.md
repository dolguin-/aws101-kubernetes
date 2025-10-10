# Secrets Manager

- [Secrets Manager](#secrets-manager)
  - [Objetivo de la Clase](#objetivo-de-la-clase)
  - [¿Por qué usar Secrets Manager?](#por-qué-usar-secrets-manager)
  - [Conceptos Fundamentales](#conceptos-fundamentales)
    - [Backends de Secretos](#backends-de-secretos)
    - [External Secrets Operator](#external-secrets-operator)
    - [SecretStore vs ClusterSecretStore](#secretstore-vs-clustersecretstore)
  - [AWS Secrets Manager](#aws-secrets-manager)
  - [Práctica](#práctica)
    - [Preparación](#preparación)
    - [Instalación del External Secrets Operator](#instalación-del-external-secrets-operator)
    - [Configurar AWS Secrets Manager](#configurar-aws-secrets-manager)
    - [Crear SecretStore](#crear-secretstore)
    - [Crear ExternalSecret](#crear-externalsecret)
    - [Verificar la sincronización](#verificar-la-sincronización)
  - [Otros Backends Soportados](#otros-backends-soportados)
  - [Comandos útiles](#comandos-útiles)
  - [Remover los recursos](#remover-los-recursos)
  - [Disclaimer](#disclaimer)
  - [Referencias](#referencias)
  - [Autor](#autor)

## Objetivo de la Clase

Aprender a integrar sistemas externos de gestión de secretos como AWS Secrets Manager con Kubernetes, utilizando External Secrets Operator para sincronizar secretos de manera segura y automatizada.

## ¿Por qué usar Secrets Manager?

En la [Clase 8 - Secretos](../clase-8/) aprendimos los conceptos básicos de secretos en Kubernetes y cómo crearlos manualmente. Sin embargo, en entornos de producción necesitamos una gestión más robusta y segura de secretos.

### Limitaciones de los Secretos Nativos de Kubernetes

- **Gestión manual**: Crear y actualizar secretos requiere intervención manual
- **Rotación compleja**: Cambiar secretos implica múltiples pasos manuales
- **Falta de auditoría**: Difícil rastrear quién accede o modifica secretos
- **Almacenamiento local**: Los secretos se almacenan en etcd del cluster
- **Sin versionado**: No hay historial de cambios en los secretos

### Beneficios de External Secrets Manager

- **Centralización**: Un solo lugar para gestionar todos los secretos
- **Rotación automática**: Los secretos se actualizan automáticamente
- **Auditoría completa**: Logs detallados de acceso y modificaciones
- **Múltiples backends**: Soporte para AWS, Azure, GCP, HashiCorp Vault, etc.
- **Seguridad mejorada**: Secretos nunca se almacenan en código o manifiestos
- **Compliance**: Cumple con estándares de seguridad empresariales

## Conceptos Fundamentales

### Backends de Secretos

Los **backends** son sistemas externos que almacenan y gestionan secretos de forma segura:

- **AWS Secrets Manager**: Servicio nativo de AWS
- **HashiCorp Vault**: Solución open-source popular
- **Azure Key Vault**: Servicio de Microsoft Azure
- **Google Secret Manager**: Servicio de Google Cloud
- **Kubernetes Secrets**: Para casos simples

### External Secrets Operator

El **External Secrets Operator (ESO)** es un operador de Kubernetes que:

- Sincroniza secretos desde sistemas externos
- Mantiene los secretos actualizados automáticamente
- Soporta múltiples proveedores de secretos
- Proporciona recursos CRD para configuración declarativa

### SecretStore vs ClusterSecretStore

- **SecretStore**: Configuración de backend a nivel de namespace
- **ClusterSecretStore**: Configuración global para todo el cluster

## AWS Secrets Manager

AWS Secrets Manager es un servicio completamente administrado que:

- **Almacena secretos** de forma segura y encriptada
- **Rota automáticamente** credenciales de bases de datos
- **Integra con servicios AWS** como RDS, Redshift, DocumentDB
- **Proporciona auditoría** completa con CloudTrail
- **Controla acceso** mediante IAM policies

## Práctica

### Preparación

Creamos el namespace para esta práctica:

```bash
kubectl create namespace clase15
```

### Instalación del External Secrets Operator

```bash
# Agregar repositorio de Helm
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

# Instalar External Secrets Operator
helm install external-secrets external-secrets/external-secrets \
  --namespace external-secrets-system \
  --create-namespace

# Verificar instalación
kubectl get pods -n external-secrets-system
```

### Configurar AWS Secrets Manager

#### Crear secreto en AWS Secrets Manager

```bash
# Crear secreto con AWS CLI
aws secretsmanager create-secret \
  --name "clase15/database-credentials" \
  --description "Credenciales de base de datos para clase 15" \
  --secret-string '{"username":"admin","password":"mi-password-super-secreto","host":"db.ejemplo.com","port":"5432"}'

# Verificar creación
aws secretsmanager describe-secret --secret-id "clase15/database-credentials"
```

#### Configurar IAM para acceso

```bash
# Crear policy IAM (guardar como iam-policy.json)
cat > iam-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret"
            ],
            "Resource": "arn:aws:secretsmanager:*:*:secret:clase15/*"
        }
    ]
}
EOF

# Crear policy
aws iam create-policy \
  --policy-name ExternalSecretsPolicy \
  --policy-document file://iam-policy.json

# Crear service account con IRSA (si usas EKS)
eksctl create iamserviceaccount \
  --name external-secrets-sa \
  --namespace clase15 \
  --cluster tu-cluster-name \
  --attach-policy-arn arn:aws:iam::ACCOUNT-ID:policy/ExternalSecretsPolicy \
  --approve
```

### Crear SecretStore

```yaml
# secretstore.yaml
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

```bash
kubectl apply -f secretstore.yaml
```

### Crear ExternalSecret

```yaml
# external-secret.yaml
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
  - secretKey: host
    remoteRef:
      key: clase15/database-credentials
      property: host
  - secretKey: port
    remoteRef:
      key: clase15/database-credentials
      property: port
```

```bash
kubectl apply -f external-secret.yaml
```

### Verificar la sincronización

```bash
# Verificar ExternalSecret
kubectl get externalsecret -n clase15

# Verificar que el Secret fue creado
kubectl get secret database-credentials -n clase15

# Ver contenido del secret (base64 decoded)
kubectl get secret database-credentials -n clase15 -o jsonpath='{.data.username}' | base64 -d
kubectl get secret database-credentials -n clase15 -o jsonpath='{.data.password}' | base64 -d

# Verificar logs del operator
kubectl logs -n external-secrets-system deployment/external-secrets
```

## Otros Backends Soportados

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
# Listar todos los ExternalSecrets
kubectl get externalsecret -A

# Ver estado detallado de un ExternalSecret
kubectl describe externalsecret database-secret -n clase15

# Forzar sincronización inmediata
kubectl annotate externalsecret database-secret -n clase15 force-sync=$(date +%s)

# Ver logs del operator
kubectl logs -n external-secrets-system -l app.kubernetes.io/name=external-secrets

# Verificar SecretStore
kubectl get secretstore -n clase15

# Listar secretos sincronizados
kubectl get secret -n clase15 -l managed-by=external-secrets

# Verificar conectividad con backend
kubectl get secretstore aws-secrets-manager -n clase15 -o yaml
```

## Remover los recursos

Para limpiar todos los recursos creados:

```bash
# Eliminar ExternalSecret y SecretStore
kubectl delete externalsecret database-secret -n clase15
kubectl delete secretstore aws-secrets-manager -n clase15

# Eliminar secreto de AWS
aws secretsmanager delete-secret --secret-id "clase15/database-credentials" --force-delete-without-recovery

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
