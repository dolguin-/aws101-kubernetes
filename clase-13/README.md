# ArgoCD

- [ArgoCD](#argocd)
  - [Objetivo de la Clase](#objetivo-de-la-clase)
  - [¿Qué es ArgoCD?](#qué-es-argocd)
  - [GitOps](#gitops)
  - [Instalación de ArgoCD](#instalación-de-argocd)
    - [Requisitos](#requisitos)
  - [Práctica](#práctica)
    - [Preparación](#preparación)
    - [Instalación con Helm](#instalación-con-helm)
    - [Verificamos la configuración](#verificamos-la-configuración)
    - [Acceso a la interfaz web](#acceso-a-la-interfaz-web)
  - [Comandos útiles](#comandos-útiles)
  - [Remover los recursos](#remover-los-recursos)
  - [Disclaimer](#disclaimer)
  - [Referencias](#referencias)
  - [Autor](#autor)

## Objetivo de la Clase

Desplegar ArgoCD en nuestro cluster de Kubernetes utilizando Helm para implementar GitOps y automatizar el despliegue de aplicaciones desde repositorios Git.

## ¿Qué es ArgoCD?

ArgoCD es una herramienta de entrega continua declarativa para Kubernetes que sigue el patrón GitOps. Permite automatizar el despliegue de aplicaciones manteniendo el estado deseado definido en repositorios Git.

ArgoCD monitorea continuamente los repositorios Git especificados y compara el estado actual del cluster con el estado deseado definido en Git, aplicando automáticamente los cambios cuando detecta diferencias.

## GitOps

GitOps es una metodología operacional que utiliza Git como fuente única de verdad para la infraestructura y aplicaciones. Los principios fundamentales son:

- **Declarativo**: Todo el sistema se describe declarativamente
- **Versionado e inmutable**: El estado deseado se almacena en Git
- **Automatizado**: Los cambios se aplican automáticamente
- **Monitoreo continuo**: El sistema se auto-corrige constantemente

## Instalación de ArgoCD

### Requisitos

- Cluster de Kubernetes funcionando
- Helm 3 instalado
- kubectl configurado
- Acceso a internet para descargar imágenes

## Práctica

### Preparación

Agregamos el repositorio de Helm de ArgoCD y actualizamos:

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```

### Instalación con Helm

Creamos el namespace y desplegamos ArgoCD:

```bash
# Crear namespace
kubectl create namespace argocd

# Instalar ArgoCD
helm install argocd argo/argo-cd \
  --namespace argocd \
  --set server.service.type=LoadBalancer
```

### Verificamos la configuración

Verificamos que todos los pods estén ejecutándose:

```bash
kubectl get pods -n argocd
kubectl get svc -n argocd
```

Obtenemos la contraseña inicial del admin:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Acceso a la interfaz web

Para acceder a la interfaz web de ArgoCD:

```bash
# Obtener la IP del LoadBalancer
kubectl get svc argocd-server -n argocd

# O usar port-forward si no tienes LoadBalancer
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

**Credenciales de acceso:**
- **Usuario**: admin
- **Contraseña**: La obtenida en el paso anterior
- **URL**: https://EXTERNAL-IP o https://localhost:8080

## Comandos útiles

```bash
# Ver todos los recursos de ArgoCD
kubectl get all -n argocd

# Ver logs del servidor
kubectl logs -n argocd deployment/argocd-server

# Ver aplicaciones en ArgoCD
kubectl get applications -n argocd

# Sincronizar aplicación manualmente
kubectl patch app NOMBRE-APP -n argocd --type merge --patch='{"operation":{"initiatedBy":{"username":"admin"},"sync":{"syncStrategy":{"hook":{}}}}}'
```

## Remover los recursos

Para limpiar todos los recursos creados:

```bash
# Desinstalar ArgoCD
helm uninstall argocd -n argocd

# Eliminar namespace
kubectl delete namespace argocd
```

## Disclaimer

El participante es 100% responsable de los costos generados al realizar las prácticas. Desde este espacio renunciamos a toda responsabilidad por costos generados al realizar los laboratorios.

Les pedimos que sean conscientes de remover todos los recursos utilizados cuando finalicen las prácticas.

## Referencias

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [GitOps Principles](https://www.gitops.tech/)
- [ArgoCD Helm Chart](https://github.com/argoproj/argo-helm)

## Autor

**Damian A. Gitto Olguin**
[AWS Community Hero](https://www.youtube.com/c/damianolguinAWSHERO)
[@enlink](https://twitter.com/enlink) / [@teracloudio](https://twitter.com/teracloudio)
<https://teracloud.io>
