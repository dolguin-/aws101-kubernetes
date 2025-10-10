# Kubernetes Monitoreo Avanzado

- [Kubernetes Monitoreo Avanzado](#kubernetes-monitoreo-avanzado)
  - [Objetivo de la Clase](#objetivo-de-la-clase)
  - [¿Por qué monitorear Kubernetes?](#por-qué-monitorear-kubernetes)
  - [Componentes del Stack de Monitoreo](#componentes-del-stack-de-monitoreo)
    - [Metrics Server](#metrics-server)
    - [Prometheus](#prometheus)
    - [Grafana](#grafana)
    - [Loki](#loki)
  - [Arquitectura de Monitoreo](#arquitectura-de-monitoreo)
  - [Práctica](#práctica)
    - [Preparación](#preparación)
    - [Habilitar Metrics Server](#habilitar-metrics-server)
    - [Instalar Stack de Monitoreo](#instalar-stack-de-monitoreo)
    - [Configurar Grafana](#configurar-grafana)
    - [Verificar Métricas](#verificar-métricas)
    - [Configurar Dashboards](#configurar-dashboards)
  - [Comandos útiles](#comandos-útiles)
  - [Dashboards Recomendados](#dashboards-recomendados)
  - [Troubleshooting](#troubleshooting)
  - [Remover los recursos](#remover-los-recursos)
  - [Disclaimer](#disclaimer)
  - [Referencias](#referencias)
  - [Autor](#autor)

## Objetivo de la Clase

Establecer **sistemas de monitoreo avanzados** para nuestro cluster de Kubernetes utilizando herramientas que se ejecutan dentro del propio cluster: Metrics Server, Prometheus, Grafana, Loki y Thanos para obtener observabilidad completa y almacenamiento a largo plazo.

### ¿Por qué monitoreo interno al cluster?

Existen múltiples opciones para monitorear clusters de Kubernetes:

**Servicios nativos de cloud providers:**
- **AWS** - CloudWatch Container Insights, X-Ray
- **Google Cloud** - Cloud Monitoring, Cloud Logging
- **Azure** - Azure Monitor, Application Insights

**Plataformas de terceros:**
- **Datadog** - Monitoreo SaaS completo
- **New Relic** - Observabilidad como servicio
- **Splunk** - Análisis de logs y métricas

**¿Por qué elegimos herramientas internas?**

En esta clase nos enfocamos en herramientas que **corren dentro de nuestro cluster** porque:

- **Control total** - Configuración y personalización completa
- **Independencia** - No dependes de servicios externos
- **Costo-efectivo** - Sin tarifas por volumen de datos
- **Privacidad** - Los datos nunca salen del cluster
- **Aprendizaje** - Entender cómo funciona el monitoreo internamente
- **Portabilidad** - Funciona en cualquier cluster, cualquier proveedor

## ¿Por qué monitorear Kubernetes?

El monitoreo en Kubernetes es esencial para:

- **Observabilidad completa** - Métricas, logs y trazas de todo el cluster
- **Detección temprana** - Identificar problemas antes de que afecten usuarios
- **Optimización de recursos** - Entender el uso de CPU, memoria y almacenamiento
- **Troubleshooting** - Diagnosticar problemas de rendimiento y disponibilidad
- **Capacity planning** - Planificar el crecimiento y escalamiento
- **SLA compliance** - Monitorear disponibilidad y tiempo de respuesta

## Componentes del Stack de Monitoreo

### Metrics Server

**Metrics Server** es un agregador de métricas de recursos del cluster que:

- Recolecta métricas de CPU y memoria de nodos y pods
- Habilita comandos como `kubectl top`
- Proporciona métricas para Horizontal Pod Autoscaler (HPA)
- Es requerido para el autoescalado de pods

### Prometheus

**Prometheus** es un sistema de monitoreo y alertas que:

- Recolecta métricas de aplicaciones y servicios
- Almacena datos en series temporales
- Proporciona un lenguaje de consulta potente (PromQL)
- Genera alertas basadas en reglas
- Se integra con múltiples exportadores

### Grafana

**Grafana** es una plataforma de visualización que:

- Crea dashboards interactivos y personalizables
- Se conecta a múltiples fuentes de datos
- Proporciona alertas visuales
- Permite compartir dashboards con equipos
- Ofrece una amplia biblioteca de dashboards comunitarios

### Thanos

**Thanos** es un sistema de almacenamiento a largo plazo para Prometheus que:

- Proporciona almacenamiento ilimitado para métricas históricas
- Permite consultas globales a través de múltiples clusters
- Compacta y deduplica datos automáticamente
- Se integra con almacenamiento en la nube (S3, GCS, Azure)
- Mantiene alta disponibilidad y escalabilidad
- Reduce costos de almacenamiento con compresión

### Loki

**Loki** es un sistema de agregación de logs que:

- Recolecta y almacena logs de aplicaciones
- Se integra nativamente con Grafana
- Utiliza etiquetas para indexación eficiente
- Proporciona consultas similares a Prometheus (LogQL)
- Escalable y eficiente en almacenamiento

## Arquitectura de Monitoreo

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Aplicaciones  │    │      Nodos      │    │   Kubernetes    │
│                 │    │                 │    │     API         │
└─────────┬───────┘    └─────────┬───────┘    └─────────┬───────┘
          │                      │                      │
          │ métricas             │ métricas             │ métricas
          │                      │                      │
          ▼                      ▼                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                        Prometheus                               │
│                 (Recolección y Almacenamiento)                 │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          │ métricas
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Thanos                                 │
│              (Almacenamiento a Largo Plazo)                    │
│                    ┌─────────────────┐                         │
│                    │   Object Store  │                         │
│                    │   (S3/GCS/etc)  │                         │
│                    └─────────────────┘                         │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          │ consultas históricas
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Grafana                                │
│                    (Visualización y Dashboards)               │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────┐    ┌─────────────────┐
│   Aplicaciones  │    │      Pods       │
│     (logs)      │    │     (logs)      │
└─────────┬───────┘    └─────────┬───────┘
          │                      │
          │ logs                 │ logs
          │                      │
          ▼                      ▼
┌─────────────────────────────────────────┐
│                 Loki                    │
│         (Agregación de Logs)            │
└─────────────────┬───────────────────────┘
                  │
                  │ consultas
                  ▼
┌─────────────────────────────────────────┐
│               Grafana                   │
│        (Visualización de Logs)          │
└─────────────────────────────────────────┘
```

## Práctica

### Preparación

```bash
# Crear namespace para monitoreo
kubectl create namespace monitoring
```

### Habilitar Metrics Server

#### Para Minikube
```bash
# Habilitar metrics-server addon
minikube addons enable metrics-server

# Verificar
kubectl get pods -n kube-system | grep metrics-server
```

#### Para otros clusters
```bash
# Instalar metrics-server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Verificar instalación
kubectl get deployment metrics-server -n kube-system
```

### Instalar Stack de Monitoreo

```bash
# Agregar repositorios de Helm
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Instalar kube-prometheus-stack con configuración para Thanos
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.service.type=LoadBalancer \
  --set prometheus.service.type=LoadBalancer \
  --set prometheus.prometheusSpec.thanos.image=quay.io/thanos/thanos:v0.32.5 \
  --set prometheus.prometheusSpec.thanos.version=v0.32.5 \
  --set prometheus.prometheusSpec.retention=2h \
  --set prometheus.prometheusSpec.retentionSize=1GB

# Instalar Thanos para almacenamiento a largo plazo
helm install thanos bitnami/thanos \
  --namespace monitoring \
  --set query.enabled=true \
  --set queryFrontend.enabled=true \
  --set compactor.enabled=true \
  --set storegateway.enabled=true \
  --set ruler.enabled=false \
  --set receive.enabled=false \
  --set bucketweb.enabled=true \
  --set minio.enabled=true \
  --set minio.auth.rootUser=admin \
  --set minio.auth.rootPassword=minio123

# Instalar Loki
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --set grafana.enabled=false \
  --set prometheus.enabled=false \
  --set promtail.enabled=true

# Verificar instalación
kubectl get pods -n monitoring
```

### Configurar Grafana

#### Acceso en clusters con LoadBalancer (EKS/GKE/AKS)
```bash
# Obtener contraseña de Grafana
kubectl get secret monitoring-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 -d

# Obtener IP externa del LoadBalancer
kubectl get svc monitoring-grafana -n monitoring
# Acceder a http://EXTERNAL-IP
```

#### Acceso en clusters locales (Minikube/Kind)
```bash
# Si tienes MetalLB instalado en Minikube
kubectl get svc monitoring-grafana -n monitoring
# Debería mostrar una IP externa asignada por MetalLB

# Si el LoadBalancer está en <pending> sin MetalLB, usar port-forward
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80

# O cambiar el servicio a NodePort
kubectl patch svc monitoring-grafana -n monitoring -p '{"spec":{"type":"NodePort"}}'

# Para Minikube sin MetalLB, usar tunnel
minikube tunnel
```

### Verificar Métricas

```bash
# Verificar metrics-server
kubectl top nodes
kubectl top pods -A

# Acceder a Prometheus (métricas recientes)
kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090

# Acceder a Thanos Query (métricas históricas)
kubectl port-forward svc/thanos-query -n monitoring 9091:9090

# Acceder a Thanos Bucket Web (explorar almacenamiento)
kubectl port-forward svc/thanos-bucketweb -n monitoring 8080:8080

# Verificar Loki
kubectl port-forward svc/loki -n monitoring 3100:3100

# Verificar MinIO (almacenamiento de objetos para Thanos)
kubectl port-forward svc/thanos-minio -n monitoring 9000:9000
```

### Configurar Dashboards

Una vez que Grafana esté accesible, necesitamos configurar las fuentes de datos y importar dashboards para visualizar las métricas de nuestro cluster.

#### 1. Acceder a Grafana
```bash
# Obtener contraseña de admin
kubectl get secret monitoring-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 -d

# Acceder a Grafana en http://localhost:3000 (con port-forward)
# Usuario: admin
# Contraseña: La obtenida arriba
```

#### 2. Configurar Data Sources

Grafana necesita saber dónde obtener los datos. Configuraremos Prometheus, Thanos y Loki como fuentes de datos:

**Prometheus (Métricas recientes - últimas 2 horas):**
- Ir a **Configuration > Data Sources**
- Click **Add data source**
- Seleccionar **Prometheus**
- URL: `http://monitoring-kube-prometheus-prometheus:9090`
- Click **Save & Test**

**Thanos Query (Métricas históricas - almacenamiento a largo plazo):**
- Click **Add data source** nuevamente
- Seleccionar **Prometheus**
- Name: `Thanos`
- URL: `http://thanos-query:9090`
- Click **Save & Test**

**Loki (Logs):**
- Click **Add data source** nuevamente
- Seleccionar **Loki**
- URL: `http://loki:3100`
- Click **Save & Test**

#### 3. Importar Dashboards

Grafana tiene una biblioteca extensa de dashboards comunitarios. Importaremos algunos específicos para Kubernetes:

**Método de importación:**
- Ir a **+ > Import**
- Ingresar el ID del dashboard
- Click **Load**
- Seleccionar la fuente de datos (Prometheus)
- Click **Import**

**Dashboards recomendados:**

**Kubernetes Cluster Monitoring (ID: 7249)**
- Vista general del cluster
- Métricas de nodos, pods y recursos
- Estado general de salud del cluster

**Node Exporter Full (ID: 1860)**
- Métricas detalladas de nodos
- CPU, memoria, disco, red por nodo
- Información del sistema operativo

**Kubernetes Pod Monitoring (ID: 6417)**
- Monitoreo específico de pods
- Uso de recursos por pod
- Reinicios y estados de pods

#### 4. Verificar Visualización

Después de importar los dashboards:

1. **Navegar a los dashboards** importados
2. **Verificar que muestren datos** (puede tomar unos minutos)
3. **Explorar las métricas** disponibles
4. **Personalizar** según necesidades específicas

#### 5. Configurar Alertas (Opcional)

```bash
# Verificar reglas de alertas existentes
kubectl get prometheusrules -n monitoring

# Las alertas aparecerán en Grafana > Alerting
```

## Comandos útiles

```bash
# Verificar métricas de recursos
kubectl top nodes
kubectl top pods -A
kubectl top pods -n monitoring

# Ver servicios de monitoreo
kubectl get svc -n monitoring

# Logs de componentes
kubectl logs -n monitoring deployment/monitoring-grafana
kubectl logs -n monitoring deployment/monitoring-kube-prometheus-operator
kubectl logs -n monitoring deployment/thanos-query
kubectl logs -n monitoring deployment/thanos-compactor

# Port-forwards útiles
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80
kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090
kubectl port-forward svc/thanos-query -n monitoring 9091:9090
kubectl port-forward svc/thanos-bucketweb -n monitoring 8080:8080
kubectl port-forward svc/loki -n monitoring 3100:3100
kubectl port-forward svc/thanos-minio -n monitoring 9000:9000

# Verificar alertas y configuración
kubectl get prometheusrules -n monitoring
kubectl get servicemonitors -n monitoring

# Verificar componentes de Thanos
kubectl get pods -n monitoring | grep thanos
kubectl get svc -n monitoring | grep thanos
```

## Dashboards Recomendados

### Dashboards de Grafana Labs
- **Kubernetes Cluster Monitoring (7249)** - Vista general del cluster
- **Node Exporter Full (1860)** - Métricas detalladas de nodos
- **Kubernetes Pod Monitoring (6417)** - Monitoreo de pods
- **Kubernetes Deployment Statefulset Daemonset (8588)** - Workloads
- **Loki Dashboard (13639)** - Visualización de logs

### Métricas Importantes
- **CPU Usage** - Utilización de procesador
- **Memory Usage** - Uso de memoria
- **Disk I/O** - Operaciones de disco
- **Network Traffic** - Tráfico de red
- **Pod Restarts** - Reinicios de pods
- **Error Rates** - Tasas de error en aplicaciones

## Troubleshooting

### LoadBalancer en estado <pending>
```bash
# Verificar estado del servicio
kubectl get svc monitoring-grafana -n monitoring

# Si tienes MetalLB instalado, verificar configuración
# Para MetalLB v0.13+ (nueva API)
kubectl get ipaddresspool -n metallb-system
kubectl get l2advertisement -n metallb-system

# Para MetalLB v0.12 y anteriores (API legacy)
kubectl get configmap config -n metallb-system -o yaml

# Verificar pods de MetalLB
kubectl get pods -n metallb-system

# Si MetalLB está configurado correctamente, debería asignar IP automáticamente
# Ejemplo: EXTERNAL-IP debería mostrar algo como 172.18.255.200

# Si sigue en <pending>:
# Solución 1: Usar port-forward
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80

# Solución 2: Cambiar a NodePort
kubectl patch svc monitoring-grafana -n monitoring -p '{"spec":{"type":"NodePort"}}'

# Solución 3: Para Minikube sin MetalLB, usar tunnel
minikube tunnel
```

### Metrics Server no funciona
```bash
# Verificar pods
kubectl get pods -n kube-system | grep metrics-server

# Ver logs
kubectl logs -n kube-system deployment/metrics-server

# Para clusters locales, puede requerir --kubelet-insecure-tls
kubectl patch deployment metrics-server -n kube-system --type='merge' -p='{"spec":{"template":{"spec":{"containers":[{"name":"metrics-server","args":["--cert-dir=/tmp","--secure-port=4443","--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname","--kubelet-use-node-status-port","--metric-resolution=15s","--kubelet-insecure-tls"]}]}}}}'
```

### Grafana no accesible
```bash
# Verificar servicio y puerto correcto
kubectl get svc monitoring-grafana -n monitoring
# PORT(S) debería mostrar 80:XXXXX/TCP

# Port-forward correcto (servicio puerto 80 -> local 3000)
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80

# Si el port-forward falla, verificar pods
kubectl get pods -n monitoring | grep grafana
kubectl describe pod -n monitoring -l app.kubernetes.io/name=grafana

# Verificar logs de Grafana
kubectl logs -n monitoring deployment/monitoring-grafana

# Alternativa: port-forward directo al pod
kubectl port-forward -n monitoring $(kubectl get pod -n monitoring -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}') 3000:3000
```

### Thanos sin datos históricos
```bash
# Verificar componentes de Thanos
kubectl get pods -n monitoring | grep thanos

# Verificar logs de Thanos Query
kubectl logs -n monitoring deployment/thanos-query

# Verificar logs de Thanos Compactor
kubectl logs -n monitoring deployment/thanos-compactor

# Verificar configuración de MinIO
kubectl get svc thanos-minio -n monitoring
kubectl port-forward svc/thanos-minio -n monitoring 9000:9000
# Acceder a http://localhost:9000 (admin/minio123)

# Verificar que Prometheus esté enviando datos a Thanos
kubectl logs -n monitoring prometheus-monitoring-kube-prometheus-prometheus-0 | grep thanos
```

### Prometheus sin datos
```bash
# Verificar servicemonitors
kubectl get servicemonitors -n monitoring

# Verificar targets en Prometheus UI
# http://localhost:9090/targets

# Verificar configuración
kubectl get prometheus -n monitoring -o yaml
```

## Remover los recursos

```bash
# Desinstalar charts de Helm
helm uninstall monitoring -n monitoring
helm uninstall thanos -n monitoring
helm uninstall loki -n monitoring

# Eliminar PVCs de MinIO (almacenamiento persistente)
kubectl delete pvc -n monitoring -l app.kubernetes.io/name=minio

# Eliminar namespace
kubectl delete namespace monitoring

# Deshabilitar metrics-server en Minikube
minikube addons disable metrics-server
```

## Disclaimer

El participante es 100% responsable de los costos generados al realizar las prácticas. Desde este espacio renunciamos a toda responsabilidad por costos generados al realizar los laboratorios.

Les pedimos que sean conscientes de remover todos los recursos utilizados cuando finalicen las prácticas.

## Referencias

- [Kubernetes Metrics Server](https://github.com/kubernetes-sigs/metrics-server)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Thanos Documentation](https://thanos.io/tip/thanos/getting-started.md/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/)
- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Thanos Helm Chart](https://github.com/bitnami/charts/tree/main/bitnami/thanos)

## Autor

**Damian A. Gitto Olguin**
[AWS Community Hero](https://www.youtube.com/c/damianolguinAWSHERO)
[@enlink](https://twitter.com/enlink) / [@teracloudio](https://twitter.com/teracloudio)
<https://teracloud.io>
