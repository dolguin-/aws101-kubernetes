# Clase 3 - Deployments y Rolling Updates

- [Clase 3 - Deployments y Rolling Updates](#clase-3---deployments-y-rolling-updates)
  - [Objetivo de la Clase](#objetivo-de-la-clase)
  - [¿Qué es un Deployment?](#qué-es-un-deployment)
  - [Deployment vs ReplicaSet](#deployment-vs-replicaset)
  - [Rolling Updates](#rolling-updates)
    - [Estrategias de actualización](#estrategias-de-actualización)
  - [Práctica con Deployments](#práctica-con-deployments)
    - [Crear un Deployment](#crear-un-deployment)
    - [Verificar el Deployment](#verificar-el-deployment)
    - [Actualizar la aplicación](#actualizar-la-aplicación)
    - [Ver el historial de rollouts](#ver-el-historial-de-rollouts)
    - [Rollback a versión anterior](#rollback-a-versión-anterior)
  - [Estrategias de Deployment](#estrategias-de-deployment)
    - [RollingUpdate (por defecto)](#rollingupdate-por-defecto)
    - [Recreate](#recreate)
  - [Comandos útiles](#comandos-útiles)
  - [Configuración avanzada](#configuración-avanzada)
  - [Conceptos clave](#conceptos-clave)
  - [Buenas prácticas](#buenas-prácticas)
  - [Troubleshooting](#troubleshooting)
  - [Referencias](#referencias)
  - [Autor](#autor)

## Objetivo de la Clase

Aprender sobre **Deployments** para gestionar aplicaciones de forma declarativa y realizar **Rolling Updates** sin downtime.

## ¿Qué es un Deployment?

Un **Deployment** es un controlador de alto nivel que gestiona ReplicaSets y proporciona actualizaciones declarativas para pods.

### Características principales:
- **Gestión de ReplicaSets**: Crea y gestiona ReplicaSets automáticamente
- **Rolling Updates**: Actualizaciones sin downtime
- **Rollback**: Vuelta atrás a versiones anteriores
- **Escalado**: Aumentar/disminuir réplicas
- **Historial**: Mantiene historial de versiones
- **Declarativo**: Define el estado deseado

## Deployment vs ReplicaSet

| Característica | ReplicaSet | Deployment |
|---|---|---|
| **Propósito** | Mantener réplicas | Gestionar aplicaciones |
| **Updates** | Manual | Automático (Rolling) |
| **Rollback** | No | Sí |
| **Historial** | No | Sí |
| **Uso directo** | Raro | Recomendado |

## Rolling Updates

Los **Rolling Updates** permiten actualizar aplicaciones gradualmente, reemplazando pods antiguos por nuevos sin interrumpir el servicio.

### Ventajas:
- **Zero downtime**: Sin interrupción del servicio
- **Gradual**: Actualización progresiva
- **Rollback rápido**: Vuelta atrás inmediata si hay problemas
- **Control**: Configuración de velocidad y estrategia

### Estrategias de actualización

#### **RollingUpdate** (por defecto)
- Reemplaza pods gradualmente
- Mantiene disponibilidad durante la actualización
- Configurable con `maxUnavailable` y `maxSurge`

#### **Recreate**
- Elimina todos los pods antes de crear nuevos
- Causa downtime temporal
- Útil para aplicaciones que no soportan múltiples versiones

## Práctica con Deployments

### Crear un Deployment

```yaml
# deployment-nginx.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.20
        ports:
        - containerPort: 80
```

```bash
# Aplicar el Deployment
kubectl apply -f deployment-nginx.yaml
```

### Verificar el Deployment

```bash
# Ver Deployments
kubectl get deployments
kubectl get deploy

# Información detallada
kubectl describe deployment nginx-deployment

# Ver ReplicaSets creados
kubectl get replicasets

# Ver pods
kubectl get pods -l app=nginx

# Estado del rollout
kubectl rollout status deployment/nginx-deployment
```

### Actualizar la aplicación

```bash
# Actualizar imagen usando kubectl
kubectl set image deployment/nginx-deployment nginx=nginx:1.21

# O editar el deployment
kubectl edit deployment nginx-deployment

# Ver el progreso del rolling update
kubectl rollout status deployment/nginx-deployment

# Ver pods durante la actualización
kubectl get pods -l app=nginx -w
```

### Ver el historial de rollouts

```bash
# Ver historial de revisiones
kubectl rollout history deployment/nginx-deployment

# Ver detalles de una revisión específica
kubectl rollout history deployment/nginx-deployment --revision=2
```

### Rollback a versión anterior

```bash
# Rollback a la versión anterior
kubectl rollout undo deployment/nginx-deployment

# Rollback a una revisión específica
kubectl rollout undo deployment/nginx-deployment --to-revision=1

# Verificar el rollback
kubectl rollout status deployment/nginx-deployment
```

## Estrategias de Deployment

### RollingUpdate (por defecto)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1      # Máximo 1 pod no disponible
      maxSurge: 1           # Máximo 1 pod extra durante update
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
```

### Recreate

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
```

## Comandos útiles

```bash
# Deployments
kubectl get deployments
kubectl describe deployment <deployment-name>
kubectl delete deployment <deployment-name>

# Escalado
kubectl scale deployment <deployment-name> --replicas=5

# Actualizaciones
kubectl set image deployment/<deployment-name> <container>=<image>
kubectl edit deployment <deployment-name>

# Rollouts
kubectl rollout status deployment/<deployment-name>
kubectl rollout history deployment/<deployment-name>
kubectl rollout undo deployment/<deployment-name>
kubectl rollout restart deployment/<deployment-name>

# Pausar/Reanudar rollouts
kubectl rollout pause deployment/<deployment-name>
kubectl rollout resume deployment/<deployment-name>

# Ver recursos relacionados
kubectl get all -l app=<app-name>
```

## Configuración avanzada

### Health Checks

```yaml
spec:
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
```

### Resource Limits

```yaml
spec:
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
```

## Conceptos clave

- **Deployment**: Controlador para gestionar aplicaciones stateless
- **Rolling Update**: Actualización gradual sin downtime
- **Rollback**: Vuelta atrás a versión anterior
- **Revision**: Versión específica de un deployment
- **maxUnavailable**: Máximo número de pods no disponibles durante update
- **maxSurge**: Máximo número de pods extra durante update
- **Strategy**: Estrategia de actualización (RollingUpdate/Recreate)
- **Rollout**: Proceso de despliegue de una nueva versión

## Buenas prácticas

### Configuración recomendada:
```yaml
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 25%
      maxSurge: 25%
  revisionHistoryLimit: 10
```

### Recomendaciones:
- **Usar Deployments** en lugar de ReplicaSets directamente
- **Configurar health checks** (liveness/readiness probes)
- **Establecer resource limits** para evitar consumo excesivo
- **Mantener historial limitado** (`revisionHistoryLimit`)
- **Usar tags específicos** de imagen (evitar `latest`)
- **Probar en staging** antes de producción
- **Monitorear** el proceso de rollout

## Troubleshooting

### Deployment stuck
```bash
# Ver estado del rollout
kubectl rollout status deployment/<name>

# Ver eventos
kubectl get events --sort-by=.metadata.creationTimestamp

# Describir deployment
kubectl describe deployment <name>

# Ver logs de pods
kubectl logs -l app=<app-name>
```

### Rollback de emergencia
```bash
# Rollback inmediato
kubectl rollout undo deployment/<name>

# Escalar a 0 si es necesario
kubectl scale deployment <name> --replicas=0
```

## Referencias

- [Deployments Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Rolling Updates](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/)
- [Deployment Strategies](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy)

## Autor

**Damian A. Gitto Olguin**
[AWS Community Hero](https://www.youtube.com/c/damianolguinAWSHERO)
[@enlink](https://twitter.com/enlink) / [@teracloudio](https://twitter.com/teracloudio)
<https://teracloud.io>
