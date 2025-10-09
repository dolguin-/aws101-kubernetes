# Minikube Setup para aws101-kubernetes

## Requisitos

- Docker Desktop instalado y ejecutándose
- kubectl instalado
- curl (para descarga automática de minikube si no está instalado)

**Nota:** El script instalará automáticamente minikube si no está presente en el sistema.

## Uso

### Script unificado

```bash
chmod +x minikube
./minikube [COMMAND]
```

### Comandos disponibles

#### Iniciar cluster
```bash
./minikube start
```

#### Detener cluster
```bash
./minikube stop
```

#### Mostrar ayuda
```bash
./minikube help
```

### Funcionalidades automáticas

El comando `start` realizará automáticamente:
1. ✅ Verificación de instalación de minikube
2. 📥 Descarga e instalación de minikube si no está presente
3. 🚀 Inicio del cluster con configuración optimizada
4. 🔧 Habilitación de addons necesarios

## Configuración del cluster

- **Kubernetes**: v1.34.0
- **Driver**: Docker (por defecto)
- **CPU**: 2 cores
- **Memoria**: 4GB
- **Disco**: 20GB
- **Addons**: ingress, dashboard, metrics-server, ingress-dns, storage-provisioner

## Opciones de Driver

### Docker (Recomendado)

```bash
minikube start --driver=docker
```

- ✅ Multiplataforma (Linux, macOS, Windows)
- ✅ Fácil instalación
- ✅ Buen rendimiento
- ❌ Requiere Docker Desktop

### VirtualBox

```bash
minikube start --driver=virtualbox
```

- ✅ Multiplataforma
- ✅ Aislamiento completo
- ❌ Rendimiento más lento
- ❌ Requiere VirtualBox instalado

### VMware (macOS/Linux)

```bash
minikube start --driver=vmware
```

- ✅ Buen rendimiento
- ✅ Aislamiento completo
- ❌ Requiere VMware Fusion/Workstation (licencia)

### HyperV (Windows)

```bash
minikube start --driver=hyperv
```

- ✅ Nativo en Windows Pro/Enterprise
- ✅ Buen rendimiento
- ❌ Solo Windows
- ❌ Requiere privilegios de administrador

### KVM2 (Linux)

```bash
minikube start --driver=kvm2
```

- ✅ Nativo en Linux
- ✅ Excelente rendimiento
- ❌ Solo Linux
- ❌ Requiere configuración adicional

### Podman (Linux/macOS)

```bash
minikube start --driver=podman
```

- ✅ Sin daemon
- ✅ Rootless
- ❌ Experimental
- ❌ Limitaciones de funcionalidad

## Comandos útiles

```bash
# Ver estado del cluster
minikube status

# Acceder al dashboard
minikube dashboard

# Ver IP del cluster
minikube ip

# SSH al nodo
minikube ssh

# Cambiar driver por defecto
minikube config set driver docker
```

## Documentación oficial

- **Minikube Drivers**: https://minikube.sigs.k8s.io/docs/drivers/
- **Docker Driver**: https://minikube.sigs.k8s.io/docs/drivers/docker/
- **VirtualBox Driver**: https://minikube.sigs.k8s.io/docs/drivers/virtualbox/
- **VMware Driver**: https://minikube.sigs.k8s.io/docs/drivers/vmware/
- **HyperV Driver**: https://minikube.sigs.k8s.io/docs/drivers/hyperv/
- **KVM2 Driver**: https://minikube.sigs.k8s.io/docs/drivers/kvm2/
- **Podman Driver**: https://minikube.sigs.k8s.io/docs/drivers/podman/
- **Guía de instalación**: https://minikube.sigs.k8s.io/docs/start/
