# Clase 2 - ReplicaSet, Labels y Selectors

- [Clase 2 - ReplicaSet, Labels y Selectors](#clase-2---replicaset-labels-y-selectors)
  - [Objetivo de la Clase](#objetivo-de-la-clase)
  - [¿Qué es un ReplicaSet?](#qué-es-un-replicaset)
  - [Labels y Selectors](#labels-y-selectors)
    - [Labels](#labels)
    - [Selectors](#selectors)
  - [Práctica con ReplicaSet](#práctica-con-replicaset)
    - [Crear un ReplicaSet](#crear-un-replicaset)
    - [Verificar el ReplicaSet](#verificar-el-replicaset)
    - [Escalar el ReplicaSet](#escalar-el-replicaset)
    - [Probar la auto-reparación](#probar-la-auto-reparación)
  - [Trabajando con Labels](#trabajando-con-labels)
    - [Agregar labels a pods existentes](#agregar-labels-a-pods-existentes)
    - [Filtrar por labels](#filtrar-por-labels)
    - [Modificar labels](#modificar-labels)
  - [Comandos útiles](#comandos-útiles)
  - [Conceptos clave](#conceptos-clave)
  - [Buenas prácticas](#buenas-prácticas)
  - [Referencias](#referencias)
  - [Autor](#autor)

## Objetivo de la Clase

Aprender sobre **ReplicaSet** para garantizar alta disponibilidad y entender el sistema de **Labels y Selectors** para organizar y filtrar recursos en Kubernetes.

## ¿Qué es un ReplicaSet?

Un **ReplicaSet** es un controlador que garantiza que un número específico de réplicas de un pod estén ejecutándose en todo momento.

### Características principales:
- **Alta disponibilidad**: Mantiene el número deseado de pods
- **Auto-reparación**: Reemplaza pods que fallan
- **Escalado**: Permite aumentar o disminuir réplicas
- **Selector-based**: Usa labels para identificar pods
- **Declarativo**: Define el estado deseado

### ¿Cuándo usar ReplicaSet?
- Aplicaciones **stateless**
- Necesidad de **múltiples réplicas**
- Garantizar **disponibilidad**
- **Escalado horizontal**

## Labels y Selectors

### Labels

Los **labels** son pares clave-valor que se adjuntan a objetos de Kubernetes para identificarlos y organizarlos.

#### Características:
- **Metadatos** flexibles
- **No únicos** (múltiples objetos pueden tener el mismo label)
- **Queryables** mediante selectors
- **Inmutables** una vez creados (se pueden agregar/eliminar)

#### Ejemplos de labels comunes:
```yaml
labels:
  app: nginx
  version: v1.2.0
  environment: production
  tier: frontend
  team: platform
```

### Selectors

Los **selectors** son consultas que permiten filtrar objetos basándose en sus labels.

#### Tipos de selectors:
- **Equality-based**: `app=nginx`, `version!=v1.0`
- **Set-based**: `environment in (production, staging)`

## ReplicaSet vs Deployment

Aunque los **ReplicaSets** son útiles, en la práctica **NO se usan directamente**. En su lugar, se utilizan **Deployments**.

### Comparación detallada:

| Característica | ReplicaSet | Deployment |
|---|---|---|
| **Gestión de réplicas** | ✅ Sí | ✅ Sí |
| **Auto-reparación** | ✅ Sí | ✅ Sí |
| **Escalado** | ✅ Manual | ✅ Manual y automático |
| **Rolling Updates** | ❌ No | ✅ Sí |
| **Rollback** | ❌ No | ✅ Sí |
| **Historial de versiones** | ❌ No | ✅ Sí |
| **Estrategias de actualización** | ❌ No | ✅ Sí (RollingUpdate/Recreate) |
| **Gestión de ReplicaSets** | ❌ Manual | ✅ Automática |
| **Zero-downtime updates** | ❌ No | ✅ Sí |
| **Uso recomendado** | ❌ No directamente | ✅ Sí |

### ¿Por qué usar Deployments en lugar de ReplicaSets?

#### **1. Actualizaciones sin downtime**
```bash
# Con ReplicaSet: Proceso manual y con downtime
kubectl delete rs nginx-replicaset
kubectl apply -f nginx-replicaset-v2.yaml

# Con Deployment: Rolling update automático
kubectl set image deployment/nginx-deployment nginx=nginx:1.22
```

#### **2. Rollback automático**
```bash
# ReplicaSet: No hay rollback, hay que recrear manualmente
kubectl apply -f nginx-replicaset-old.yaml

# Deployment: Rollback con un comando
kubectl rollout undo deployment/nginx-deployment
```

#### **3. Historial de cambios**
```bash
# ReplicaSet: Sin historial
kubectl get rs # Solo ve el estado actual

# Deployment: Historial completo
kubectl rollout history deployment/nginx-deployment
```

#### **4. Gestión automática de ReplicaSets**
Los Deployments **crean y gestionan ReplicaSets automáticamente**:

```bash
# Un Deployment crea ReplicaSets por ti
kubectl get rs
# nginx-deployment-7d6b7d6b7d   3   3   3   5m
# nginx-deployment-5c6b7d6b7d   0   0   0   2m  # ReplicaSet anterior
```

### Cuándo usar cada uno:

#### **ReplicaSet directo** (casos muy específicos):
- ❌ **Nunca en producción**
- ❌ Solo para aprendizaje o casos muy específicos
- ❌ Cuando necesitas control muy granular (muy raro)

#### **Deployment** (recomendado):
- ✅ **Siempre en producción**
- ✅ Aplicaciones web y APIs
- ✅ Microservicios
- ✅ Cualquier aplicación stateless
- ✅ Cuando necesitas actualizaciones frecuentes

### Ejemplo práctico de la diferencia:

#### Actualización con ReplicaSet (problemático):
```bash
# 1. Eliminar ReplicaSet actual (DOWNTIME!)
kubectl delete rs nginx-replicaset

# 2. Aplicar nueva versión
kubectl apply -f nginx-replicaset-v2.yaml

# 3. Si hay problemas, proceso manual de rollback
kubectl delete rs nginx-replicaset
kubectl apply -f nginx-replicaset-v1.yaml
```

#### Actualización con Deployment (sin problemas):
```bash
# 1. Rolling update automático (SIN DOWNTIME)
kubectl set image deployment/nginx-deployment nginx=nginx:1.22

# 2. Si hay problemas, rollback inmediato
kubectl rollout undo deployment/nginx-deployment
```

### Conclusión

**Los ReplicaSets son la base técnica, pero los Deployments son la herramienta práctica.**

- Los **Deployments** usan ReplicaSets internamente
- Proporcionan todas las funcionalidades de ReplicaSet **PLUS** gestión avanzada
- Son la **mejor práctica** recomendada por la comunidad Kubernetes
- **Nunca uses ReplicaSets directamente** en producción

> 💡 **Regla de oro**: Si necesitas réplicas de pods, usa **Deployment**, no ReplicaSet directamente.

## Práctica con ReplicaSet

> ⚠️ **Nota importante**: Esta práctica es solo para **fines educativos**. En producción, **siempre usa Deployments** en lugar de ReplicaSets directamente.

### Crear un ReplicaSet

```yaml
# replicaset-nginx.yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-replicaset
  labels:
    app: nginx
    tier: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
      tier: frontend
  template:
    metadata:
      labels:
        app: nginx
        tier: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:1.21
        ports:
        - containerPort: 80
```

```bash
# Aplicar el ReplicaSet
kubectl apply -f replicaset-nginx.yaml
```

### Verificar el ReplicaSet

```bash
# Ver ReplicaSets
kubectl get replicasets
kubectl get rs

# Ver información detallada
kubectl describe rs nginx-replicaset

# Ver pods creados por el ReplicaSet
kubectl get pods -l app=nginx

# Ver pods con labels
kubectl get pods --show-labels
```

### Escalar el ReplicaSet

```bash
# Escalar usando kubectl
kubectl scale rs nginx-replicaset --replicas=5

# Verificar el escalado
kubectl get rs nginx-replicaset
kubectl get pods -l app=nginx

# Escalar de vuelta
kubectl scale rs nginx-replicaset --replicas=3
```

### Probar la auto-reparación

```bash
# Eliminar un pod manualmente
kubectl delete pod <pod-name>

# Verificar que se crea uno nuevo automáticamente
kubectl get pods -l app=nginx -w
```

## Trabajando con Labels

### Agregar labels a pods existentes

```bash
# Agregar label a un pod
kubectl label pod <pod-name> environment=development

# Agregar múltiples labels
kubectl label pod <pod-name> version=v1.0 team=backend
```

### Filtrar por labels

```bash
# Filtrar pods por label
kubectl get pods -l app=nginx
kubectl get pods -l environment=production

# Múltiples labels (AND)
kubectl get pods -l app=nginx,tier=frontend

# Operadores
kubectl get pods -l 'environment in (production,staging)'
kubectl get pods -l 'version!=v1.0'

# Ver todos los labels
kubectl get pods --show-labels
```

### Modificar labels

```bash
# Cambiar valor de un label
kubectl label pod <pod-name> environment=staging --overwrite

# Eliminar un label
kubectl label pod <pod-name> environment-
```

## Comandos útiles

```bash
# ReplicaSets
kubectl get replicasets
kubectl get rs
kubectl describe rs <replicaset-name>
kubectl delete rs <replicaset-name>

# Escalado
kubectl scale rs <replicaset-name> --replicas=<number>

# Labels
kubectl get pods --show-labels
kubectl get pods -l <label-selector>
kubectl label pod <pod-name> <key>=<value>
kubectl label pod <pod-name> <key>- # eliminar label

# Selectors avanzados
kubectl get pods -l 'app in (nginx,apache)'
kubectl get pods -l 'version!=v1.0'
kubectl get pods -l app,version # pods que tienen ambos labels

# Ver eventos
kubectl get events --sort-by=.metadata.creationTimestamp

# Editar ReplicaSet
kubectl edit rs <replicaset-name>
```

## Conceptos clave

- **ReplicaSet**: Controlador que mantiene un número específico de réplicas
- **Replica**: Copia idéntica de un pod
- **Labels**: Metadatos clave-valor para identificar objetos
- **Selectors**: Consultas para filtrar objetos por labels
- **matchLabels**: Selector de igualdad exacta
- **matchExpressions**: Selector basado en expresiones
- **Template**: Plantilla para crear pods en el ReplicaSet
- **Desired State**: Estado deseado definido en el spec
- **Current State**: Estado actual del sistema

## Buenas prácticas

### Labels recomendados:
```yaml
labels:
  app.kubernetes.io/name: nginx
  app.kubernetes.io/instance: nginx-prod
  app.kubernetes.io/version: "1.21"
  app.kubernetes.io/component: frontend
  app.kubernetes.io/part-of: ecommerce
  app.kubernetes.io/managed-by: kubectl
```

### Convenciones:
- Usar **nombres descriptivos**
- Mantener **consistencia** en el naming
- Evitar **información sensible** en labels
- Usar **prefijos** para organización (`team.company.com/owner`)
- **Documentar** el esquema de labels del equipo

## Referencias

- [ReplicaSet Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/)
- [Labels and Selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
- [Recommended Labels](https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/)

## Autor

**Damian A. Gitto Olguin**
[AWS Community Hero](https://www.youtube.com/c/damianolguinAWSHERO)
[@enlink](https://twitter.com/enlink) / [@teracloudio](https://twitter.com/teracloudio)
<https://teracloud.io>
