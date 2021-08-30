# Ingress & Ingress Controllers

- [Ingress & Ingress Controllers](#ingress--ingress-controllers)
  - [Definición Ingress](#definición-ingress)
  - [Definición Ingress Controller](#definición-ingress-controller)
    - [Instalación Ingress Controller (NginX)](#instalación-ingress-controller-nginx)
    - [Otros Ingress Controllers](#otros-ingress-controllers)
  - [Ingress Yaml Manifests](#ingress-yaml-manifests)
    - [comandos utiles](#comandos-utiles)
  - [Práctica](#práctica)
    - [Preparación](#preparación)
    - [Instalamos el Ingress Controller](#instalamos-el-ingress-controller)
    - [Verificamos la configuración](#verificamos-la-configuración)
  - [Remover los recursos](#remover-los-recursos)
  - [Disclaimer](#disclaimer)
  - [Autor](#autor)

## Definición Ingress

Los Ingress son objetos de kubernetes que administran el acceso externo a servicios dentro del cluster, comúnmente HTTP.

Los ingress pueden proveer balanceo de carga, TLS/SSL, hosts virtuales basados en nombres.

Normalmente se utilizan para enrutar el protocolo HTTP y HTTPS hacia el internet (exterior del cluster) los servicios que están corriendo dentro del cluster; el tráfico es controlado a través de reglas de tráfico definidas en el recurso **Ingress**.

ref: [Documentación oficial Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)

## Definición Ingress Controller

Con el objetivo de que recursos Ingress funcionen, el cluster debe poseer un ingress controller corriendo.

A diferencia de otros tipos de controller que corren como parte del binario de Kube-controller-manager, los Ingress Controllers no se inician automáticamente con el cluster.

El Proyecto Kubernetes soporta y mantiene los siguientes ingress controllers: AWS, GCE, y NGINX.

### Instalación Ingress Controller (NginX)

Las instrucciones para instalar el ingress controller de Nginx varian segun donde esta corriendo tu cluster de kubernetes o el en los cloud providers tipo de load balancer que va a utilizar, pueden buscar la información específica para su provider en la documentacion oficial <https://kubernetes.github.io/ingress-nginx/deploy/>

En esta clase vamos a realizar la instalación para AWS con NLB utilizando el siguiente yaml manifest oficial de kubernetes, la instalación para ALB o ELB classic es muy similar.

```shell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.0/deploy/static/provider/aws/deploy.yaml

# namespace/ingress-nginx created
# serviceaccount/ingress-nginx created
# configmap/ingress-nginx-controller created
# clusterrole.rbac.authorization.k8s.io/ingress-nginx configured
# clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx configured
# role.rbac.authorization.k8s.io/ingress-nginx created
# rolebinding.rbac.authorization.k8s.io/ingress-nginx created
# service/ingress-nginx-controller-admission created
# service/ingress-nginx-controller created
# deployment.apps/ingress-nginx-controller created
# ingressclass.networking.k8s.io/nginx created
# validatingwebhookconfiguration.admissionregistration.k8s.io/ingress-nginx-admission configured
# serviceaccount/ingress-nginx-admission created
# clusterrole.rbac.authorization.k8s.io/ingress-nginx-admission configured
# clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx-admission configured
# role.rbac.authorization.k8s.io/ingress-nginx-admission created
# rolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
# job.batch/ingress-nginx-admission-create created
# job.batch/ingress-nginx-admission-patch created
```

Verificamos que el pods relacionados con el ingress controller esté corriendo y los correspondientes a los Jobs de admisión finalizará su tarea con estado completado.

```shell
kubectl -n ingress-nginx get pods
# NAME                                        READY   STATUS      RESTARTS   AGE
# ingress-nginx-admission-create-557zv        0/1     Completed   0          50s
# ingress-nginx-admission-patch-fspcc         0/1     Completed   0          50s
# ingress-nginx-controller-65c4f84996-d7fbd   1/1     Running     0          57s
```

También podemos controlar que el servicio haya sido creado y que tenga su loadbalancer asignado.

```shell
kubectl -n ingress-nginx get svc
NAME                                 TYPE           CLUSTER-IP       EXTERNAL-IP                                                                     PORT(S)                      AGE
ingress-nginx-controller             LoadBalancer   10.100.135.135   [REDACTED].elb.us-east-1.amazonaws.com   80:30311/TCP,443:30387/TCP   3m54s
ingress-nginx-controller-admission   ClusterIP      10.100.52.124    <none>                                                                          443/TCP                      3m54s
```

### Otros Ingress Controllers

- AKS Application Gateway Ingress Controller, es un controlador de ingreso que configura el gateway de aplicaciones de Azure.
- Ambassador API Gateway es un controlador de ingreso basado en Envoy.
- Apache APISIX ingress controller es un controlador de ingreso basado en Apache APISIX-based.
- Avi Kubernetes Operator provee balanceo de carga en las capas L4-L7 usando VMware NSX Advanced Load Balancer.
- El Citrix ingress controller trabaja con Citrix Application Delivery Controller.
- Contour es un controlador de ingreso basado en Envoy.
- EnRoute un Api Gateway basado en Envoy que corre como controlador de ingreso.
- Easegress IngressController es un API Gateway basado en Easegress que corre como un controlador de ingreso.
- F5 BIG-IP Container Ingress Services para Kubernetes permite un controlador de ingreso para configurar servidores virtuales F5 BIG-IP.
- Gloo es un controlador de ingreso open-source basado en Envoy, que ofrece funcionalidades de API gateway.
- HAProxy Ingress es un controlador de ingreso basado en HAProxy.
- El HAProxy Ingress Controller para Kubernetes es también un controlador de ingreso basado en HAProxy.
- Istio Ingress es un controlador de ingreso basado en Istio.
- Kong Ingress Controller para Kubernetes  es un controlador de ingreso manejado por Kong Gateway.
- El NGINX Ingress Controller para Kubernetes trabaja utilizando el servidor web NGINX (como proxy).
- Skipper HTTP router y proxy reverso para composición de servicios, incluye casos de uso como Kubernetes Ingress, diseñado como librería para construir tu propio proxy a medida.
- El Proveedor Traefik Kubernetes Ingress es un controlador de ingreso para el Traefik proxy.
- El operador Tyk Operator extiende ingress con recursos a medida para proveer capacidad de administración de API  a los ingress. El Operador de Tyk trabaja con la versión open-source de Tyk Gateway & Tyk Cloud control plane.
- Voyager  es un controlador de ingreso basado en HAProxy.

ref: [Documentación oficial Ingress Controller](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/)

## Ingress Yaml Manifests

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
 name: wp
 namespace: clase9
spec:
 ingressClassName: nginx
 rules:
 - http:
     paths:
     - path: /
       pathType: Prefix
       backend:
         service:
           name: wordpress
           port:
             number: 80
```

### comandos utiles

- Crear un ingress desde la línea de comandos

 `kubectl create ingress <NOMBRE> --rule=<RULE_DEFINITIONS>`

 `kubectl create ingress catch-all --class=otheringress --rule=<RULE_DEFINITIONS>`

- Listar Ingress

 `kubectl get ingress`

- Describir un Ingress

 `kubectl describe ingress <ingress_name>`

- Eliminar un Ingress

 `kubectl delete ingress <ingress_name>`

## Práctica

En esta clase vamos a realizar un ejercicio más similar a la vida real, vamos a desplegar un stack completo para correr wordpress incluyendo la base de datos tal y como la desplegamos en la clase anterior.
Todo lo realizaremos en el namespace `clase9` y los yamls para crear los siguientes componentes:

- Storage Class
- PVC para mariaDB
- PVC para wordpress
- Secrets para mariaDB
- Secrets para wordpress
- Deployment de MariaDB
- Service para MariaDB
- Deployment de Wordpress
- Service para Wordpress

Como verán este caso es mucho más completo que los que hemos realizado anteriormente por esta razón realizaremos el apply de una forma que aplique todos los Yamls contenidos en el directorio de trabajo `clase-9`

Como pre-requisito deberán clonar el repositorio del curso e ingresar a la carpeta `clase-9/`

### Preparación

- Aplicamos todos los manifests de la siguiente manera

  `kubectl apply -f .`

 ```shell
 cd clase-9
 kubectl apply -f .
 # namespace/clase9 created
 # persistentvolumeclaim/mariadb-data-disk created
 # persistentvolumeclaim/wp-pv-claim created
 # secret/mariadb-secrets created
 # deployment.apps/mariadb created
 # service/mariadb created
 # deployment.apps/wordpress created
 # service/wordpress created
 # ingress.networking.k8s.io/wp created
 ```

### Instalamos el Ingress Controller

Para que el objeto ingress perteneciente al namespace de `clase9` pueda realizar su trabajo depende del que exista un ingress controller desplegado y que sea de la misma clase definido en el manifest, para la clase de hoy desplegamos el ingress oficial basado en **nginx** de la forma que indicamos anteriormente

```shell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.0/deploy/static/provider/aws/deploy.yaml
```

### Verificamos la configuración

Una vez aplicados los cambios vamos a revisar que todas las cargas de trabajo se encuentren correctamente desplegadas como lo hicimos en la clase-9

Una vez que confirmamos que todos los objetos de la carga de trabajo están correctamente desplegados verificamos el Ingress.

- `kubectl -n clase9 get ingress`
- `kubectl -n clase9 describe ingress wp`

```shell
kubectl -n clase9 get ingress
# NAME   CLASS    HOSTS   ADDRESS   PORTS   AGE
# wp     <none>   *                 80      3m12s

kubectl -n clase9 describe ingress wp
# Name:             wp
# Namespace:        clase9
# Address:
# Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
# Rules:
#   Host        Path  Backends
#   ----        ----  --------
#   *
#               /   wordpress:80 (192.168.54.246:80)
# Annotations:  <none>
# Events:       <none>
```

en este punto podremos verificar con nuestro navegador accediendo con el `fqdn` del load balancer asignado al ingress controller, para obtenerlo utiliza tienes que listar los servicios en el namespace `ingress-nginx`

- `kubectl -n ingress-nginx get svc`

```shell

NAME                                 TYPE           CLUSTER-IP       EXTERNAL-IP                                                                     PORT(S)                      AGE
ingress-nginx-controller             LoadBalancer   10.100.91.69     [REDACTED].elb.us-east-1.amazonaws.com   80:31628/TCP,443:30237/TCP   2m44s
ingress-nginx-controller-admission   ClusterIP      10.100.175.236   <none>                                                                          443/TCP                      2m45s
```

## Remover los recursos

Una vez que terminen de realizar las prácticas no se olviden de remover todos los recursos para no generar gastos no esperados.

- `kubectl delete ns clase9`
- `kubectl delete -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.0.0/deploy/static/provider/aws/deploy.yaml`

```shell
eksctl delete cluster -f aws101-cluster.yaml
# 2021-08-30 00:58:22 [ℹ]  eksctl version 0.55.0
# 2021-08-30 00:58:22 [ℹ]  using region us-east-1
# 2021-08-30 00:58:22 [ℹ]  deleting EKS cluster "aws101"
# 2021-08-30 00:58:25 [ℹ]  deleted 0 Fargate profile(s)
# 2021-08-30 00:58:27 [ℹ]  cleaning up AWS load balancers created by Kubernetes objects of Kind Service or Ingress
```

## Disclaimer

Para realizar las prácticas no es necesario utilizar un cloud provider, la mayoria de las practicas se pueden realizar en [Play With K8s](https://labs.play-with-k8s.com/), de todas maneras para algunas prácticas relacionadas con componentes que solo están disponibles en un cloud provider es preferible que sea en un cloud provider como AWS, GCP o Azure.
El participante es 100% responsable de los costos generados al realizar las prácticas, desde este espacio renunciamos a toda responsabilidad por costos generados al realizar los laboratorios.
Les pedimos que sean conscientes de remover todos los recursos utilizados cuando finalicen las prácticas.

## Autor

Damian A. Gitto Olguin
[AWS Community Hero](https://www.youtube.com/c/damianolguinAWSHERO)
[@enlink](https://twitter.com/enlink)] / [@teracloudio](https://twitter.com/teracloudio)
<https://teracloud.io>
