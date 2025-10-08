# Kind - Kubernetes IN Docker

## Introducción

Kind es una implementación liviana de Kubernetes que corre sobre Docker. Su nombre proviene del inglés **Kubernetes IN Docker**.

Kind es una forma fácil y rápida de crear un cluster de Kubernetes para propósitos como:

- 🎓 Aprendizaje y desarrollo
- 🔄 Integración Continua (CI)
- 🧪 Testing de aplicaciones
- 🚀 Desarrollo local

## Requisitos

- Docker Desktop instalado y ejecutándose
- kubectl instalado
- kind instalado ([Guía de instalación](https://kind.sigs.k8s.io/docs/user/quick-start/#installation))

## Uso Rápido

### Con Makefile (Recomendado)

```bash
# Ver comandos disponibles
make help

# Crear cluster completo con MetalLB
make all

# Solo crear cluster
make install

# Solo instalar MetalLB
make lb

# Ver estado del cluster
make status

# Eliminar cluster
make delete
```

### Comandos Manuales

#### Crear cluster básico

```bash
kind create cluster --name aws101
```

#### Crear cluster con configuración personalizada

```bash
kind create cluster --name aws101 --config kind-cluster.yml
```

#### Eliminar cluster

```bash
kind delete cluster --name aws101
```

## Configuración del Cluster

El archivo `kind-cluster.yml` incluye:

- **Kubernetes v1.31.0** (última versión estable)
- **1 Control Plane + 2 Workers** para simular un entorno real
- **Port Mappings** para acceso a servicios:
  - HTTP: localhost:8080 → cluster:80
  - HTTPS: localhost:8443 → cluster:443
- **Ingress Ready** labels para controladores de ingress

## MetalLB Load Balancer

MetalLB proporciona servicios LoadBalancer en clusters locales:

- **Versión**: v0.14.8 (última estable)
- **Configuración automática** de rangos IP
- **Detección inteligente** de red Docker
- **L2 Advertisement** para balanceeo de carga

### Rangos IP por defecto

- Red `172.18.0.0/16`: IPs `172.18.255.200-172.18.255.250`
- Red `172.19.0.0/16`: IPs `172.19.255.200-172.19.255.250`

## Comandos Útiles

```bash
# Ver clusters disponibles
kind get clusters

# Cambiar contexto de kubectl
kubectl config use-context kind-aws101

# Ver información del cluster
kubectl cluster-info --context kind-aws101

# Ver nodos
kubectl get nodes

# Probar LoadBalancer
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=LoadBalancer
```

## Troubleshooting

### Problemas comunes

1. **Docker no está ejecutándose**
   ```bash
   # Verificar Docker
   docker ps
   ```

2. **Puerto ya en uso**
   ```bash
   # Cambiar puertos en kind-cluster.yml
   hostPort: 8081  # En lugar de 8080
   ```

3. **Cluster no responde**
   ```bash
   # Recrear cluster
   make delete && make install
   ```

## Comparación con Minikube

| Característica | Kind | Minikube |
|----------------|------|----------|
| **Base** | Docker containers | VM o containers |
| **Velocidad** | ⚡ Muy rápido | 🐌 Más lento |
| **Recursos** | 💚 Ligero | 🔶 Más pesado |
| **Multi-node** | ✅ Nativo | ⚠️ Experimental |
| **Addons** | ❌ Manual | ✅ Integrados |

## Enlaces Útiles

- **Documentación oficial**: https://kind.sigs.k8s.io/
- **MetalLB**: https://metallb.universe.tf/
- **Kubernetes**: https://kubernetes.io/docs/

## Autor

Damian A. Gitto Olguin
[AWS Community Hero](https://www.youtube.com/c/damianolguinAWSHERO)
[@enlink](https://twitter.com/enlink) / [@teracloudio](https://twitter.com/teracloudio)
<https://teracloud.io>
