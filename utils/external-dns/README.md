# External-DNS para AWS Route53

## Introducción

External-DNS automatiza la gestión de registros DNS en AWS Route53 basándose en recursos de Kubernetes como Services e Ingress.

## Requisitos

- Cluster EKS funcionando
- Dominio registrado en Route53
- Permisos IAM configurados
- kubectl configurado

## Configuración

### 1. Crear IAM Policy

```bash
# Crear policy con permisos Route53
aws iam create-policy \
  --policy-name ExternalDNSPolicy \
  --policy-document file://iam_policy.json
```

### 2. Crear IAM Role para Service Account

```bash
# Obtener OIDC issuer del cluster
CLUSTER_NAME="aws101"
OIDC_ISSUER=$(aws eks describe-cluster \
  --name $CLUSTER_NAME \
  --query "cluster.identity.oidc.issuer" \
  --output text)

# Crear role con trust policy
eksctl create iamserviceaccount \
  --cluster=$CLUSTER_NAME \
  --namespace=default \
  --name=external-dns \
  --attach-policy-arn=arn:aws:iam::ACCOUNT_ID:policy/ExternalDNSPolicy \
  --override-existing-serviceaccounts \
  --approve
```

### 3. Configurar Deployment

Editar `4-extdns-deployment.yaml`:

```yaml
# Actualizar estos valores:
annotations:
  iam.amazonaws.com/role: arn:aws:iam::ACCOUNT_ID:role/eksctl-CLUSTER-addon-iamserviceaccount-Role

args:
  - --domain-filter=tu-dominio.com  # Tu dominio
  - --txt-owner-id=tu-cluster-id    # ID único del cluster
```

### 4. Obtener Hosted Zone ID

```bash
# Listar hosted zones
aws route53 list-hosted-zones --query "HostedZones[?Name=='tu-dominio.com.']"

# Actualizar iam_policy.json con el Zone ID real
```

## Instalación

### Opción 1: Aplicar manifiestos individuales

```bash
kubectl apply -f 1-extdns-service_account.yaml
kubectl apply -f 2-extdns-cluster_role.yaml
kubectl apply -f 3-extdns-crole_binding.yaml
kubectl apply -f 4-extdns-deployment.yaml
```

### Opción 2: Aplicar todos los manifiestos

```bash
kubectl apply -f .
```

## Ejemplos de Configuración

### Entornos por separado

#### Producción
```bash
kubectl apply -f examples/production-example.yaml
```
- 2 réplicas para alta disponibilidad
- Política `upsert-only` (no elimina registros)
- Health checks configurados
- Recursos optimizados

#### Staging
```bash
kubectl apply -f examples/staging-example.yaml
```
- 1 réplica
- Política `sync` (permite eliminación)
- Log level debug para troubleshooting

#### Desarrollo
```bash
kubectl apply -f examples/development-example.yaml
```
- Recursos mínimos
- Modo `dry-run` para testing
- Log level debug

### Configuraciones especiales

#### Multi-dominio
```bash
kubectl apply -f examples/multi-domain-example.yaml
```
- Gestiona múltiples dominios
- Filtros específicos por subdominio

#### Zona privada
```bash
kubectl apply -f examples/private-zone-example.yaml
```
- Para dominios internos
- `aws-zone-type=private`

## Verificación

### Comprobar pods

```bash
kubectl get pods -l app=external-dns
kubectl logs -l app=external-dns
```

### Probar con Service LoadBalancer

```bash
# Crear servicio de prueba
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=LoadBalancer
kubectl annotate service nginx external-dns.alpha.kubernetes.io/hostname=test.tu-dominio.com
```

### Probar con Ingress

```bash
# Crear ingress de prueba
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: test-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - host: app.tu-dominio.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nginx
            port:
              number: 80
EOF
```

## Configuración Avanzada

### Variables de entorno importantes

| Variable | Descripción | Ejemplo |
|----------|-------------|---------|
| `--domain-filter` | Dominios a gestionar | `example.com` |
| `--txt-owner-id` | ID único del cluster | `my-cluster-1` |
| `--policy` | Política de sincronización | `upsert-only` |
| `--aws-zone-type` | Tipo de zona Route53 | `public` |
| `--registry` | Tipo de registro | `txt` |

### Políticas de sincronización

- **sync** (default): Crea, actualiza y elimina registros
- **upsert-only**: Solo crea y actualiza, nunca elimina

### Filtros de dominio

```yaml
args:
  - --domain-filter=example.com
  - --domain-filter=subdomain.example.com
```

## Troubleshooting

### Problemas comunes

#### 1. Permisos IAM insuficientes

```bash
# Verificar permisos del role
aws sts get-caller-identity
aws iam get-role --role-name eksctl-CLUSTER-addon-iamserviceaccount-Role
```

#### 2. External-DNS no crea registros

```bash
# Verificar logs
kubectl logs -l app=external-dns -f

# Verificar anotaciones
kubectl get service nginx -o yaml | grep annotations -A 5
```

#### 3. Registros DNS no se resuelven

```bash
# Verificar en Route53
aws route53 list-resource-record-sets --hosted-zone-id ZONE_ID

# Probar resolución DNS
nslookup test.tu-dominio.com
```

### Logs útiles

```bash
# Logs detallados
kubectl logs -l app=external-dns --tail=100

# Seguir logs en tiempo real
kubectl logs -l app=external-dns -f
```

## Seguridad

### Principio de menor privilegio

La IAM policy incluye solo los permisos mínimos necesarios:

- `route53:ChangeResourceRecordSets` - Solo en hosted zones específicas
- `route53:ListHostedZones` - Solo lectura global
- `route53:ListResourceRecordSets` - Solo lectura global

### Aislamiento por namespace

Para usar en múltiples namespaces, actualizar ClusterRoleBinding:

```yaml
subjects:
- kind: ServiceAccount
  name: external-dns
  namespace: production
- kind: ServiceAccount
  name: external-dns
  namespace: staging
```

## Ejemplos de uso

### Service con anotación DNS

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-app
  annotations:
    external-dns.alpha.kubernetes.io/hostname: api.example.com
spec:
  type: LoadBalancer
  ports:
  - port: 80
  selector:
    app: my-app
```

### Ingress con múltiples hosts

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-host
spec:
  rules:
  - host: app1.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app1
            port:
              number: 80
  - host: app2.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app2
            port:
              number: 80
```

## Referencias

- [External-DNS Documentation](https://github.com/kubernetes-sigs/external-dns)
- [AWS Route53 Provider](https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/aws.md)
- [EKS IAM Roles for Service Accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)

## Autor

Damian A. Gitto Olguin
[AWS Community Hero](https://www.youtube.com/c/damianolguinAWSHERO)
[@enlink](https://twitter.com/enlink) / [@teracloudio](https://twitter.com/teracloudio)
<https://teracloud.io>
