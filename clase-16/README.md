# Monitoreo en Kubernetes

- [Monitoreo en Kubernetes](#monitoreo-en-kubernetes)
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

Implementar un stack completo de monitoreo en Kubernetes utilizando Metrics Server, Prometheus, Grafana y Loki para obtener visibilidad completa del cluster, aplicaciones y logs.

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
│                    (Recolección y Almacenamiento)              │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          │ consultas
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
helm repo update

# Instalar kube-prometheus-stack (Prometheus + Grafana)
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.service.type=LoadBalancer \
  --set prometheus.service.type=LoadBalancer

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

```bash
# Obtener contraseña de Grafana
kubectl get secret monitoring-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 -d

# Acceder a Grafana
kubectl get svc monitoring-grafana -n monitoring

# O usar port-forward
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80
```

### Verificar Métricas

```bash
# Verificar metrics-server
kubectl top nodes
kubectl top pods -A

# Acceder a Prometheus
kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090

# Verificar Loki
kubectl port-forward svc/loki -n monitoring 3100:3100
```

### Configurar Dashboards

1. **Acceder a Grafana** (http://localhost:3000)
   - Usuario: `admin`
   - Contraseña: La obtenida anteriormente

2. **Configurar Data Sources:**
   - Prometheus: `http://monitoring-kube-prometheus-prometheus:9090`
   - Loki: `http://loki:3100`

3. **Importar Dashboards:**
   - Kubernetes Cluster Monitoring: ID `7249`
   - Node Exporter Full: ID `1860`
   - Kubernetes Pod Monitoring: ID `6417`

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

# Port-forwards útiles
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80
kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090
kubectl port-forward svc/loki -n monitoring 3100:3100

# Verificar alertas
kubectl get prometheusrules -n monitoring
kubectl get servicemonitors -n monitoring
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
# Verificar servicio
kubectl get svc monitoring-grafana -n monitoring

# Verificar pods
kubectl get pods -n monitoring | grep grafana

# Usar port-forward como alternativa
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80
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
helm uninstall loki -n monitoring

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
- [Grafana Documentation](https://grafana.com/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/)
- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)

## Autor

**Damian A. Gitto Olguin**
[AWS Community Hero](https://www.youtube.com/c/damianolguinAWSHERO)
[@enlink](https://twitter.com/enlink) / [@teracloudio](https://twitter.com/teracloudio)
<https://teracloud.io>
