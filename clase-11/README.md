# Clase 11 - Certificados TLS en Kubernetes

- [Clase 11 - Certificados TLS en Kubernetes](#clase-11---certificados-tls-en-kubernetes)
  - [Objetivo de la Clase](#objetivo-de-la-clase)
  - [¿Qué son los Certificados TLS?](#qué-son-los-certificados-tls)
  - [Certificados en Kubernetes](#certificados-en-kubernetes)
    - [Tipos de certificados](#tipos-de-certificados)
    - [Almacenamiento en Kubernetes](#almacenamiento-en-kubernetes)
  - [Métodos de Gestión de Certificados](#métodos-de-gestión-de-certificados)
    - [1. Importación Manual (Esta Clase)](#1-importación-manual-esta-clase)
    - [2. Cloud Provider (Recomendado en Producción)](#2-cloud-provider-recomendado-en-producción)
    - [3. Cert-Manager (Automatización)](#3-cert-manager-automatización)
  - [Práctica: Importar Certificados Manualmente](#práctica-importar-certificados-manualmente)
    - [Arquitectura del Ejemplo](#arquitectura-del-ejemplo)
    - [Paso 1: Crear Namespace](#paso-1-crear-namespace)
    - [Paso 2: Configurar Almacenamiento](#paso-2-configurar-almacenamiento)
    - [Paso 3: Crear Certificado TLS](#paso-3-crear-certificado-tls)
    - [Paso 4: Desplegar MariaDB](#paso-4-desplegar-mariadb)
    - [Paso 5: Desplegar WordPress](#paso-5-desplegar-wordpress)
    - [Paso 6: Configurar Ingress con TLS](#paso-6-configurar-ingress-con-tls)
    - [Paso 7: Configurar External DNS](#paso-7-configurar-external-dns)
  - [Verificación y Testing](#verificación-y-testing)
  - [Alternativas en Producción](#alternativas-en-producción)
    - [AWS Certificate Manager (ACM)](#aws-certificate-manager-acm)
    - [Cert-Manager con Let's Encrypt](#cert-manager-con-lets-encrypt)
  - [Comandos útiles](#comandos-útiles)
  - [Troubleshooting](#troubleshooting)
  - [Conceptos clave](#conceptos-clave)
  - [Buenas prácticas](#buenas-prácticas)
  - [Referencias](#referencias)
  - [Autor](#autor)

## Objetivo de la Clase

Aprender a **importar certificados TLS** en Kubernetes de forma manual para comprender el proceso, mientras se entiende que en **producción** se utilizan alternativas automatizadas como **AWS ACM** o **Cert-Manager**.

> ⚠️ **Nota Importante**: Esta clase es **ilustrativa y educativa**. En ambientes de producción cloud, se recomienda usar certificados gestionados por el proveedor (AWS ACM, Google SSL, Azure SSL) o automatización con Cert-Manager + Let's Encrypt.

## ¿Qué son los Certificados TLS?

Los **certificados TLS** (Transport Layer Security) son archivos digitales que:

- **Autentican** la identidad de un sitio web
- **Cifran** la comunicación entre cliente y servidor
- **Garantizan** la integridad de los datos
- **Habilitan HTTPS** en aplicaciones web

### Componentes de un certificado:
- **Certificado público** (.crt o .pem) - Se comparte públicamente
- **Clave privada** (.key) - Se mantiene secreta
- **Cadena de certificados** - Certificados intermedios y raíz

## Certificados en Kubernetes

### Tipos de certificados

#### **Self-signed** (Auto-firmados)
- ✅ Fáciles de crear para desarrollo/testing
- ❌ No son confiables para usuarios finales
- ❌ Generan advertencias en navegadores

#### **CA-signed** (Firmados por Autoridad Certificadora)
- ✅ Confiables para usuarios finales
- ✅ Sin advertencias en navegadores
- ❌ Requieren validación y renovación manual

#### **Let's Encrypt**
- ✅ Gratuitos y automáticos
- ✅ Renovación automática
- ✅ Ampliamente confiables

### Almacenamiento en Kubernetes

Los certificados se almacenan como **Secrets** de tipo `tls`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: tls-secret
  namespace: default
type: kubernetes.io/tls
data:
  tls.crt: <base64-encoded-certificate>
  tls.key: <base64-encoded-private-key>
```

## Métodos de Gestión de Certificados

### 1. Importación Manual (Esta Clase)

**Propósito**: Educativo y comprensión del proceso

```bash
# Crear certificado self-signed
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt -subj "/CN=example.com"

# Importar a Kubernetes
kubectl create secret tls my-tls-secret \
  --cert=tls.crt --key=tls.key
```

**Cuándo usar**:
- ✅ Desarrollo y testing
- ✅ Aprendizaje
- ❌ **Nunca en producción**

### 2. Cloud Provider (Recomendado en Producción)

#### **AWS Certificate Manager (ACM)**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-ssl-cert: "arn:aws:acm:region:account:certificate/cert-id"
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "http"
```

**Ventajas**:
- ✅ **Renovación automática**
- ✅ **Gestión centralizada**
- ✅ **Integración nativa** con AWS Load Balancers
- ✅ **Sin costo adicional**

### 3. Cert-Manager (Automatización)

```yaml
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: example-com-tls
spec:
  secretName: example-com-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - example.com
  - www.example.com
```

**Ventajas**:
- ✅ **Renovación automática**
- ✅ **Let's Encrypt gratuito**
- ✅ **Multi-cloud**
- ✅ **Gestión declarativa**

## Práctica: Importar Certificados Manualmente

### Arquitectura del Ejemplo

Esta práctica despliega una aplicación **WordPress + MariaDB** con certificados TLS:

```
Internet → Ingress (TLS) → WordPress Service → WordPress Pod
                                    ↓
                            MariaDB Service → MariaDB Pod
```

### Paso 1: Crear Namespace

```bash
# Aplicar namespace
kubectl apply -f 00-namespace.yaml

# Verificar
kubectl get namespaces
```

### Paso 2: Configurar Almacenamiento

```bash
# Crear PVCs para persistencia
kubectl apply -f 01.1-pvc-maria.yaml
kubectl apply -f 01.2-pvc-wp.yaml

# Verificar PVCs
kubectl get pvc -n clase11
```

### Paso 3: Crear Certificado TLS

```bash
# Generar certificado self-signed (incluido en el repo)
./create_cert.sh

# O usar el certificado pre-generado
kubectl apply -f 07.0-secret-certificate.yaml

# Verificar secret
kubectl get secret -n clase11
kubectl describe secret tls-secret -n clase11
```

### Paso 4: Desplegar MariaDB

```bash
# Crear secret para MariaDB
kubectl apply -f 02.0-secret-mariadb.yaml

# Desplegar MariaDB
kubectl apply -f 03.1-mariadb-deployent.yaml
kubectl apply -f 03.2-mariadb-service.yaml

# Verificar deployment
kubectl get pods -n clase11
kubectl logs -f deployment/mariadb -n clase11
```

### Paso 5: Desplegar WordPress

```bash
# Desplegar WordPress
kubectl apply -f 04.1-wordpress-deployent.yaml
kubectl apply -f 04.2-wordpress-service.yaml

# Verificar deployment
kubectl get pods -n clase11
kubectl logs -f deployment/wordpress -n clase11
```

### Paso 6: Configurar Ingress con TLS

```bash
# Aplicar Ingress con certificado TLS
kubectl apply -f 05.00-ingress.yaml

# Verificar Ingress
kubectl get ingress -n clase11
kubectl describe ingress wordpress-ingress -n clase11
```

### Paso 7: Configurar External DNS

```bash
# Configurar External DNS (si tienes Route53)
kubectl apply -f 06.0-extdns-service_account.yaml
kubectl apply -f 06.1-extdns-cluster_role.yaml
kubectl apply -f 06.2-extdns-crole_binding.yaml
kubectl apply -f 06.3-extdns-deployment.yaml

# Verificar External DNS
kubectl get pods -n clase11
kubectl logs -f deployment/external-dns -n clase11
```

## Verificación y Testing

```bash
# Ver todos los recursos
kubectl get all -n clase11

# Verificar certificado en el Ingress
kubectl get ingress wordpress-ingress -n clase11 -o yaml

# Test de conectividad
curl -k https://your-domain.com

# Verificar certificado con openssl
openssl s_client -connect your-domain.com:443 -servername your-domain.com
```

## Alternativas en Producción

### AWS Certificate Manager (ACM)

#### Ventajas:
- ✅ **Renovación automática** cada 60 días
- ✅ **Validación automática** (DNS o email)
- ✅ **Integración nativa** con ELB/ALB
- ✅ **Sin costo adicional**
- ✅ **Gestión centralizada** en AWS Console

#### Configuración:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:123456789:certificate/abc123
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS":443}]'
    alb.ingress.kubernetes.io/redirect-to-https: "true"
```

### Cert-Manager con Let's Encrypt

#### Instalación:
```bash
# Instalar Cert-Manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Configurar ClusterIssuer
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

#### Uso:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - example.com
    secretName: example-com-tls
```

## Comandos útiles

```bash
# Certificados y Secrets
kubectl get secrets -n <namespace>
kubectl describe secret <secret-name> -n <namespace>
kubectl create secret tls <name> --cert=<cert-file> --key=<key-file>

# Verificar certificado
openssl x509 -in certificate.crt -text -noout
openssl x509 -in certificate.crt -dates -noout

# Ingress
kubectl get ingress -n <namespace>
kubectl describe ingress <ingress-name> -n <namespace>

# Testing TLS
curl -k https://domain.com
openssl s_client -connect domain.com:443

# Logs
kubectl logs -f deployment/<deployment-name> -n <namespace>
```

## Troubleshooting

### Certificado no válido
```bash
# Verificar formato del certificado
openssl x509 -in tls.crt -text -noout

# Verificar secret
kubectl get secret tls-secret -o yaml

# Recrear secret
kubectl delete secret tls-secret
kubectl create secret tls tls-secret --cert=tls.crt --key=tls.key
```

### Ingress no funciona
```bash
# Verificar Ingress Controller
kubectl get pods -n ingress-nginx

# Verificar configuración
kubectl describe ingress <ingress-name>

# Ver logs del Ingress Controller
kubectl logs -f deployment/ingress-nginx-controller -n ingress-nginx
```

### WordPress no conecta a MariaDB
```bash
# Verificar pods
kubectl get pods -n clase11

# Verificar logs
kubectl logs deployment/wordpress -n clase11
kubectl logs deployment/mariadb -n clase11

# Verificar servicios
kubectl get svc -n clase11
```

## Conceptos clave

- **TLS/SSL**: Protocolo de seguridad para cifrar comunicaciones
- **Certificado**: Archivo que autentica la identidad de un servidor
- **Clave privada**: Archivo secreto usado para descifrar datos
- **CA (Certificate Authority)**: Entidad que firma certificados
- **Self-signed**: Certificado firmado por sí mismo (no confiable)
- **Secret TLS**: Tipo especial de Secret para almacenar certificados
- **Ingress**: Controlador que maneja el tráfico HTTP/HTTPS entrante
- **ACM**: AWS Certificate Manager para gestión automática de certificados

## Buenas prácticas

### En Desarrollo:
- ✅ Usar certificados self-signed para testing
- ✅ Automatizar la creación con scripts
- ✅ Usar dominios locales (.local, .test)

### En Producción:
- ✅ **Usar AWS ACM** para certificados en AWS
- ✅ **Usar Cert-Manager** para automatización multi-cloud
- ✅ **Renovación automática** siempre
- ✅ **Monitorear expiración** de certificados
- ✅ **Usar dominios reales** validados
- ❌ **Nunca usar certificados self-signed**
- ❌ **Nunca gestionar certificados manualmente**

### Seguridad:
- 🔒 **Proteger claves privadas** (nunca en repositorios)
- 🔒 **Usar Secrets** para almacenar certificados
- 🔒 **Rotar certificados** regularmente
- 🔒 **Usar TLS 1.2+** mínimo
- 🔒 **Validar cadena de certificados**

## Referencias

- [Kubernetes TLS Secrets](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)
- [Ingress TLS](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls)
- [AWS Certificate Manager](https://aws.amazon.com/certificate-manager/)
- [Cert-Manager Documentation](https://cert-manager.io/docs/)
- [Let's Encrypt](https://letsencrypt.org/)
- [OpenSSL Commands](https://www.openssl.org/docs/man1.1.1/man1/openssl.html)

## Autor

**Damian A. Gitto Olguin**
[AWS Community Hero](https://www.youtube.com/c/damianolguinAWSHERO)
[@enlink](https://twitter.com/enlink) / [@teracloudio](https://twitter.com/teracloudio)
<https://teracloud.io>
