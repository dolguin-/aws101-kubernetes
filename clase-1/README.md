# Clase 1 - Arquitectura de Kubernetes y Pods

- [Clase 1 - Arquitectura de Kubernetes y Pods](#clase-1---arquitectura-de-kubernetes-y-pods)
  - [Objetivo de la Clase](#objetivo-de-la-clase)
  - [¿Qué es Kubernetes?](#qué-es-kubernetes)
  - [Arquitectura de Kubernetes](#arquitectura-de-kubernetes)
    - [Control Plane (Master)](#control-plane-master)
    - [Worker Nodes](#worker-nodes)
  - [¿Qué es un Pod?](#qué-es-un-pod)
  - [Práctica con Pods](#práctica-con-pods)
    - [Crear un Pod simple](#crear-un-pod-simple)
    - [Ver información del Pod](#ver-información-del-pod)
    - [Acceder al Pod](#acceder-al-pod)
    - [Eliminar el Pod](#eliminar-el-pod)
  - [Comandos útiles](#comandos-útiles)
  - [Conceptos clave](#conceptos-clave)
  - [Referencias](#referencias)
  - [Autor](#autor)

## Objetivo de la Clase

Entender la **arquitectura de Kubernetes** y aprender a trabajar con **Pods**, la unidad más pequeña de despliegue en Kubernetes.

## ¿Qué es Kubernetes?

Kubernetes (K8s) es una plataforma de orquestación de contenedores que automatiza el despliegue, escalado y gestión de aplicaciones containerizadas.

### Características principales:
- **Orquestación** de contenedores
- **Escalado automático** de aplicaciones
- **Auto-reparación** (self-healing)
- **Balanceador de carga** integrado
- **Gestión de configuración** y secretos
- **Rolling updates** sin downtime

## Arquitectura de Kubernetes

### Control Plane (Master)

Componentes que gestionan el cluster:

#### **API Server**
- Punto de entrada para todas las operaciones
- Expone la API REST de Kubernetes
- Valida y procesa las peticiones

#### **etcd**
- Base de datos distribuida
- Almacena toda la configuración del cluster
- Fuente de verdad del estado deseado

#### **Scheduler**
- Decide en qué nodo ejecutar los pods
- Considera recursos, políticas y restricciones
- Optimiza la distribución de workloads

#### **Controller Manager**
- Ejecuta los controladores del sistema
- Monitorea el estado actual vs deseado
- Toma acciones correctivas automáticamente

### Worker Nodes

Componentes que ejecutan las aplicaciones:

#### **kubelet**
- Agente que corre en cada nodo
- Comunica con el API Server
- Gestiona los pods y contenedores

#### **kube-proxy**
- Proxy de red en cada nodo
- Implementa servicios de Kubernetes
- Maneja el balanceador de carga

#### **Container Runtime**
- Ejecuta los contenedores (Docker, containerd, CRI-O)
- Gestiona imágenes y ciclo de vida

## ¿Qué es un Pod?

Un **Pod** es la unidad más pequeña de despliegue en Kubernetes:

- Contiene **uno o más contenedores**
- Comparten **red y almacenamiento**
- Tienen una **IP única** en el cluster
- Son **efímeros** (se crean y destruyen)
- Escalan como **unidad atómica**

### Características de los Pods:
- **Shared Network**: Todos los contenedores comparten la misma IP
- **Shared Storage**: Pueden compartir volúmenes
- **Lifecycle**: Nacen, viven y mueren como unidad
- **Scheduling**: Se programan juntos en el mismo nodo

## Práctica con Pods

### Crear un Pod simple

```yaml
# pod-nginx.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.21
    ports:
    - containerPort: 80
```

```bash
# Aplicar el Pod
kubectl apply -f pod-nginx.yaml

# Verificar que se creó
kubectl get pods
```

### Ver información del Pod

```bash
# Información básica
kubectl get pod nginx-pod

# Información detallada
kubectl describe pod nginx-pod

# Ver logs
kubectl logs nginx-pod

# Ver logs en tiempo real
kubectl logs -f nginx-pod
```

### Acceder al Pod

```bash
# Port forward para acceder localmente
kubectl port-forward nginx-pod 8080:80

# Abrir en navegador: http://localhost:8080

# Ejecutar comandos dentro del Pod
kubectl exec -it nginx-pod -- /bin/bash

# Ejecutar comando específico
kubectl exec nginx-pod -- ls -la /usr/share/nginx/html
```

### Eliminar el Pod

```bash
# Eliminar usando el archivo
kubectl delete -f pod-nginx.yaml

# Eliminar por nombre
kubectl delete pod nginx-pod
```

## Comandos útiles

```bash
# Listar todos los pods
kubectl get pods

# Ver pods con más información
kubectl get pods -o wide

# Ver pods en todos los namespaces
kubectl get pods --all-namespaces

# Describir un pod específico
kubectl describe pod <pod-name>

# Ver logs de un pod
kubectl logs <pod-name>

# Acceder a un pod interactivamente
kubectl exec -it <pod-name> -- /bin/bash

# Port forward
kubectl port-forward <pod-name> <local-port>:<pod-port>

# Ver eventos del cluster
kubectl get events --sort-by=.metadata.creationTimestamp

# Ver recursos del cluster
kubectl get all
```

## Conceptos clave

- **Cluster**: Conjunto de nodos que ejecutan aplicaciones containerizadas
- **Node**: Máquina física o virtual que ejecuta pods
- **Pod**: Unidad más pequeña de despliegue, contiene uno o más contenedores
- **Container**: Aplicación empaquetada con sus dependencias
- **Image**: Plantilla inmutable para crear contenedores
- **Namespace**: Separación lógica de recursos en el cluster
- **Label**: Metadatos clave-valor para identificar y seleccionar objetos
- **Selector**: Consulta para filtrar objetos por labels

## Referencias

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Kubernetes Concepts](https://kubernetes.io/docs/concepts/)
- [Pod Overview](https://kubernetes.io/docs/concepts/workloads/pods/)
- [Kubernetes Architecture](https://kubernetes.io/docs/concepts/overview/components/)

## Autor

**Damian A. Gitto Olguin**
[AWS Community Hero](https://www.youtube.com/c/damianolguinAWSHERO)
[@enlink](https://twitter.com/enlink) / [@teracloudio](https://twitter.com/teracloudio)
<https://teracloud.io>
