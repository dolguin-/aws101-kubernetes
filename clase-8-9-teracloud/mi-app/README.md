# Mi App - Helm Chart

Un chart simple de Helm para desplegar una aplicación web con nginx.

## Instalación

```bash
# Instalar el chart
helm install mi-aplicacion ./mi-app

# Instalar con valores personalizados
helm install mi-aplicacion ./mi-app --set replicaCount=3

# Actualizar
helm upgrade mi-aplicacion ./mi-app --set image.tag=1.22

# Desinstalar
helm uninstall mi-aplicacion
```

## Configuración

Principales valores configurables en `values.yaml`:

- `replicaCount`: Número de réplicas (default: 2)
- `image.repository`: Imagen de contenedor (default: nginx)
- `image.tag`: Tag de la imagen (default: 1.21)
- `service.type`: Tipo de servicio (default: ClusterIP)
- `service.port`: Puerto del servicio (default: 80)

## Verificar

```bash
# Ver el estado
helm status mi-aplicacion

# Ver los recursos creados
kubectl get all -l app=mi-app
```
