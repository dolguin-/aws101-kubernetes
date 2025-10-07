# Minikube Setup para aws101-kubernetes

## Requisitos

- Docker Desktop instalado y ejecutándose
- Minikube instalado
- kubectl instalado

## Uso

### Iniciar cluster

```bash
chmod +x minikube-setup.sh
./minikube-setup.sh
```

### Detener cluster

```bash
chmod +x minikube-stop.sh
./minikube-stop.sh
```

## Configuración del cluster

- **Kubernetes**: v1.31.0
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
