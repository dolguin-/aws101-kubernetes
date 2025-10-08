# Curso gratuito de Kubernetes en Español

[![CI](https://github.com/dolguin-/aws101-kubernetes/actions/workflows/main.yml/badge.svg)](https://github.com/dolguin-/aws101-kubernetes/actions/workflows/main.yml)
[![Release](https://img.shields.io/github/v/release/dolguin-/aws101-kubernetes)](https://github.com/dolguin-/aws101-kubernetes/releases)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.31-blue)](https://kubernetes.io/)

## Prefacio

Este curso surge de la necesidad de generar contenido de calidad de tecnologías cloud en español, puntualmente abarca los conceptos más importantes de Kubernetes comenzando desde cero.

Semanalmente se publican videos en mi canal de Youtube [Damian Olguin [AWS Hero]](https://youtube.com/playlist?list=PLQ1M3apmTbgNRyHqBQ7FRml64XV-GpIRt) y son complementados con el material contenido en este repositorio.

## 🚀 Características

- **Kubernetes 1.31** compatible
- **Manifiestos actualizados** con las últimas APIs estables
- **Desarrollo local** con Minikube y Kind
- **Producción en AWS** con EKS
- **Almacenamiento** con EFS y CSI drivers
- **DNS automático** con External-DNS
- **Ejemplos prácticos** listos para usar

## 📚 Clases

1. **Clase 1** - Arquitectura de K8s y Pods
   - [Video](https://youtu.be/Sccd454SgWk) | [Material](clase-1/)

2. **Clase 2** - ReplicaSet, Labels, Selectors
   - [Video](https://youtu.be/nxnYLDhE5jE) | [Material](clase-2/)

3. **Clase 3** - Deployments, Rolling updates
   - [Video](https://youtu.be/ifKWY7NxxVg) | [Material](clase-3/)

4. **Clase 4** - Servicios
   - [Video](https://youtu.be/52Upml2z2So) | [Material](clase-4/)

5. **Clase 5** - ConfigMaps
   - [Video](https://youtu.be/9icw5dLgXzU) | [Material](clase-5/)

6. **Clase 6** - Volúmenes
   - [Video](https://youtu.be/Jw4kMG7x_HE) | [Material](clase-6/)

7. **Clase 7** - Volúmenes Persistentes
   - [Video](https://youtu.be/R_9YAsW0cU4) | [Material](clase-7/)

8. **Clase 8** - Secretos
   - [Video](https://youtu.be/l1jh0RA6Fpk) | [Material](clase-8/)

9. **Clase 9** - Ingress básico
   - [Video](https://youtu.be/ltCgxwGAaQI) | [Material](clase-9/)

10. **Clase 10** - External DNS
    - [Material](clase-10/)

11. **Clase 11** - Certificados TLS
    - [Material](clase-11/)

12. **Clase 12** - Cert-Manager
    - [Material](clase-12/)

## 🛠️ Herramientas y Utilidades

### Desarrollo Local

#### 🐳 **Minikube**
Cluster Kubernetes local con Docker
```bash
cd utils/minikube
./minikube-setup.sh
```
- Kubernetes 1.31
- Múltiples drivers (Docker, VirtualBox, VMware, etc.)
- Addons preconfigurados
- [Documentación completa](utils/minikube/)

#### 🎯 **Kind**
Kubernetes IN Docker para CI/CD
```bash
cd utils/kind
make all
```
- Cluster multi-nodo
- MetalLB load balancer
- Port mappings para ingress
- [Documentación completa](utils/kind/)

### Producción en AWS

#### ☁️ **EKS Cluster**
```bash
eksctl create cluster -f aws101-cluster.yaml
```
- Kubernetes 1.31
- Instancias t3.medium
- OIDC y add-ons preconfigurados

#### 📁 **Amazon EFS**
Almacenamiento compartido escalable
```bash
cd utils/efs
./create-efs.sh -c aws101
```
- Creación automática de EFS
- Mount targets en todas las subnets
- Security groups configurados
- [Documentación y ejemplos](utils/efs/)

#### 💾 **EFS CSI Driver**
Driver para usar EFS en Kubernetes
```bash
cd utils/csi
./setup-efs-csi.sh aws101
```
- Instalación automatizada
- IAM roles y policies
- Ejemplos de StorageClass y PVC
- [Documentación completa](utils/csi/)

#### 🌐 **External-DNS**
DNS automático para servicios
```bash
kubectl apply -f utils/external-dns/
```
- Integración con Route53
- Múltiples entornos (prod/staging/dev)
- Configuraciones de seguridad
- [Documentación y ejemplos](utils/external-dns/)

## 🚀 Inicio Rápido

### Desarrollo Local

```bash
# 1. Clonar repositorio
git clone https://github.com/dolguin-/aws101-kubernetes.git
cd aws101-kubernetes

# 2. Iniciar cluster local
cd utils/minikube
./minikube-setup.sh

# 3. Aplicar ejemplos
kubectl apply -f clase-1/
```

### Producción AWS

```bash
# 1. Crear cluster EKS
eksctl create cluster -f aws101-cluster.yaml

# 2. Configurar almacenamiento
cd utils/efs && ./create-efs.sh -c aws101
cd ../csi && ./setup-efs-csi.sh aws101

# 3. Configurar DNS
kubectl apply -f utils/external-dns/
```

## 📋 Requisitos

### Para desarrollo local:
- Docker Desktop
- kubectl
- Minikube o Kind

### Para AWS:
- AWS CLI configurado
- eksctl
- Permisos IAM apropiados

## 🔧 Compatibilidad

- **Kubernetes**: 1.31 (todas las APIs estables)
- **AWS EKS**: Versiones soportadas
- **Docker**: 20.10+
- **Sistemas**: Linux, macOS, Windows

## 📖 Documentación Adicional

- [Minikube Setup](utils/minikube/README.md)
- [Kind Configuration](utils/kind/README.md)
- [EFS Integration](utils/efs/readme.md)
- [CSI Driver Setup](utils/csi/README.md)
- [External-DNS Configuration](utils/external-dns/README.md)

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor:

1. Fork el repositorio
2. Crea un feature branch
3. Commit tus cambios
4. Abre un Pull Request

## ⚠️ Disclaimer

El participante es 100% responsable de los costos generados al realizar las prácticas. Desde este espacio renunciamos a toda responsabilidad por costos generados al realizar los laboratorios.

Les pedimos que sean conscientes de remover todos los recursos utilizados cuando finalicen las prácticas.

## 👨‍💻 Autor

**Damian A. Gitto Olguin**
[AWS Community Hero](https://www.youtube.com/c/damianolguinAWSHERO)
[@enlink](https://twitter.com/enlink) / [@teracloudio](https://twitter.com/teracloudio)
<https://teracloud.io>

## 📄 Licencia

Este proyecto está bajo la licencia MIT. Ver [LICENSE](LICENSE) para más detalles.
