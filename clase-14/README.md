# Helm Charts

- [Helm Charts](#helm-charts)
  - [Objetivo de la Clase](#objetivo-de-la-clase)
  - [¿Qué es Helm?](#qué-es-helm)
  - [Conceptos Fundamentales](#conceptos-fundamentales)
    - [Charts](#charts)
    - [Releases](#releases)
    - [Values](#values)
  - [Estructura de un Helm Chart](#estructura-de-un-helm-chart)
  - [Práctica](#práctica)
    - [Preparación](#preparación)
    - [Instalación de Helm](#instalación-de-helm)
    - [Crear nuestro primer Chart](#crear-nuestro-primer-chart)
    - [Personalizar el Chart](#personalizar-el-chart)
    - [Desplegar la aplicación](#desplegar-la-aplicación)
    - [Actualizar el Release](#actualizar-el-release)
  - [Comandos útiles](#comandos-útiles)
  - [Remover los recursos](#remover-los-recursos)
  - [Disclaimer](#disclaimer)
  - [Referencias](#referencias)
  - [Autor](#autor)

## Objetivo de la Clase

Aprender a crear, personalizar y gestionar aplicaciones en Kubernetes utilizando Helm Charts, el gestor de paquetes de Kubernetes que simplifica el despliegue y mantenimiento de aplicaciones complejas.

## ¿Qué es Helm?

Helm es el gestor de paquetes para Kubernetes, a menudo llamado "el apt/yum/homebrew de Kubernetes". Permite definir, instalar y actualizar aplicaciones de Kubernetes de manera consistente y reproducible.

Helm utiliza un formato de empaquetado llamado **charts**, que son colecciones de archivos que describen un conjunto relacionado de recursos de Kubernetes.

## Conceptos Fundamentales

### Charts

Un **Chart** es un paquete de Helm que contiene toda la información necesaria para ejecutar una aplicación, herramienta o servicio dentro de un cluster de Kubernetes.

### Releases

Un **Release** es una instancia de un chart ejecutándose en un cluster de Kubernetes. Un mismo chart puede ser instalado múltiples veces en el mismo cluster, cada instalación crea un nuevo release.

### Values

Los **Values** son los parámetros de configuración que permiten personalizar un chart sin modificar los templates originales.

## Estructura de un Helm Chart

```
mi-chart/
├── Chart.yaml          # Información sobre el chart
├── values.yaml         # Valores por defecto
├── charts/             # Charts dependientes
├── templates/          # Templates de Kubernetes
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   └── _helpers.tpl    # Helpers y funciones
└── .helmignore         # Archivos a ignorar
```

## Práctica

### Preparación

Creamos el namespace para esta práctica:

```bash
kubectl create namespace clase14
```

### Instalación de Helm

#### En macOS
```bash
# Con Homebrew
brew install helm

# O con script oficial
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

#### En Linux
```bash
# Descargar e instalar
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

#### Verificar instalación
```bash
helm version
```

### Crear nuestro primer Chart

```bash
# Crear un chart básico
helm create mi-app

# Explorar la estructura
ls -la mi-app/
```

### Personalizar el Chart

Editamos `mi-app/values.yaml` para personalizar nuestra aplicación:

```yaml
# values.yaml
replicaCount: 2

image:
  repository: nginx
  pullPolicy: IfNotPresent
  tag: "1.21"

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: false

resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

### Desplegar la aplicación

```bash
# Validar el chart
helm lint mi-app/

# Ver los manifiestos generados (dry-run)
helm install mi-app ./mi-app --namespace clase14 --dry-run --debug

# Instalar el chart
helm install mi-app ./mi-app --namespace clase14

# Verificar el despliegue
helm list -n clase14
kubectl get all -n clase14
```

### Actualizar el Release

```bash
# Modificar values.yaml (cambiar replicas a 3)
# Luego actualizar
helm upgrade mi-app ./mi-app --namespace clase14

# Ver historial de releases
helm history mi-app -n clase14

# Rollback si es necesario
helm rollback mi-app 1 -n clase14
```

## Comandos útiles

```bash
# Listar charts instalados
helm list -A

# Ver valores de un release
helm get values mi-app -n clase14

# Ver manifiestos de un release
helm get manifest mi-app -n clase14

# Buscar charts en repositorios
helm search repo nginx

# Agregar repositorio
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Instalar desde repositorio
helm install my-nginx bitnami/nginx -n clase14

# Desinstalar release
helm uninstall mi-app -n clase14

# Crear package del chart
helm package mi-app/

# Validar chart
helm lint mi-app/
```

## Remover los recursos

Para limpiar todos los recursos creados:

```bash
# Desinstalar todos los releases
helm uninstall mi-app -n clase14

# Eliminar namespace
kubectl delete namespace clase14
```

## Disclaimer

El participante es 100% responsable de los costos generados al realizar las prácticas. Desde este espacio renunciamos a toda responsabilidad por costos generados al realizar los laboratorios.

Les pedimos que sean conscientes de remover todos los recursos utilizados cuando finalicen las prácticas.

## Referencias

- [Helm Documentation](https://helm.sh/docs/)
- [Helm Charts Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Artifact Hub](https://artifacthub.io/)
- [Helm Chart Templates](https://helm.sh/docs/chart_template_guide/)

## Autor

**Damian A. Gitto Olguin**
[AWS Community Hero](https://www.youtube.com/c/damianolguinAWSHERO)
[@enlink](https://twitter.com/enlink) / [@teracloudio](https://twitter.com/teracloudio)
<https://teracloud.io>
