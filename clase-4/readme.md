# Servicios en Kubernetes

## Servicios

Los Servicios de k8s son una forma abstracta de exponer una aplicación que se ejecuta de manera distribuida en un grupo de Pods.

Es una forma **abstracta** por que no tenes que modificar tu aplicacion cuando la despleges en distintos lugares para adaptarse al ambiente, por que **k8s** te proporciona esta capacidad de service discovery por medio de esta pone disponible tu aplicacion.

## Tipos de Servicios

Existen cuatro tipos de servicios que podemos utilizar en los cluster de Kubernetes.

### ClusterIP

Es el servicio por defecto, expone el servicio de forma **interna**, de manera que pueda ser alcanzado **solamente desde dentro del cluster**.

Esto es util para servicios que son privados que no queremos que sean expuestos a internet.

### NodePort

Expone el servicio utilizando el/los IP y un puerto estatico de los nodos, a su vez le asigna automaricamente un ClusterIP que utilizara para routear el trafico dentro del cluster para alcanzar a los pods.

### LoadBalancer

Quiza unos de los mas utilizados en produccion, expone el servicio atraves de un load balancer provicionado por el cloud provider, utiliza el Cloud Controler Manager **C-C-M** para comunicarse con el cloud provider y solicitar los recuros y crearlos **automagicamente**.

El load balancer se encarga de routear el trafico utilizando NodePorts y ClusterIP a donde se encuentre corriendo.

### ExternalName

El tipo External Name relaciona un servicio con un nombre DNS definido externamente al cluster, este tipo de servicio no es de los mas utilizado.

## Practica

Para esta clase vamos a crear el name space `clase4` luego vamos a desplegar nuestra aplicacion `Hola-aws101` a travez de un `deployment` llamado `clase4`.

### Preparacion

```shell
# Aplicamos el manifest que crea nuestro namespace
kubectl apply -f https://raw.githubusercontent.com/dolguin-/aws101-kubernetes/clase-4/clase-4/00-namespace.yaml

# aplicamos el manifest que despliega nuesro deployment
kubectl apply -f https://raw.githubusercontent.com/dolguin-/aws101-kubernetes/clase-4/clase-4/01-deployment.yaml

# Controlamos que nuestro deployment ya este listo
kubectl -n clase4 get deployment
# NAME     READY   UP-TO-DATE   AVAILABLE   AGE
# clase4   2/2     2            2           102m

kubectl -n clase4 describe deployment clase4

# Name:                   clase4
# Namespace:              clase4
# CreationTimestamp:      Sat, 31 Jul 2021 21:17:31 -0300
# Labels:                 app=clase4
# Annotations:            deployment.kubernetes.io/revision: 1
# Selector:               app=clase4
# Replicas:               2 desired | 2 updated | 2 total | 2 available | 0 unavailable
# StrategyType:           RollingUpdate
# MinReadySeconds:        0
# RollingUpdateStrategy:  25% max unavailable, 25% max surge
# Pod Template:
#   Labels:  app=clase4
#   Containers:
#    hola-aws101:
#     Image:        dolguin/hola-aws101:latest
#     Port:         80/TCP
#     Host Port:    0/TCP
#     Environment:  <none>
#     Mounts:       <none>
#   Volumes:        <none>
# Conditions:
#   Type           Status  Reason
#   ----           ------  ------
#   Available      True    MinimumReplicasAvailable
#   Progressing    True    NewReplicaSetAvailable
# OldReplicaSets:  <none>
# NewReplicaSet:   clase4-75b7bb8f4f (2/2 replicas created)
# Events:          <none>
```

Una vez aplicados estos cambios estamos listo para provar las distintas formas de exponer la aplicacion atravez de servicios.

### Ejemplo de ClusterIP

Primero vamos a probar **ClusterIP**, qui podemos ver que el servicio tendra una ip privada internal del cluster y un puerto asignado por el cual otros PODS podran alcanzar nuestro servicio.

```shell
# creamos el servicio
kubectl apply -f https://raw.githubusercontent.com/dolguin-/aws101-kubernetes/clase-4/clase-4/02-service_clusterIP.yaml

# chequeamos que este aplicado
kubectl -n clase4 get svc
# NAME     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
# clase4   ClusterIP   10.100.236.78   <none>        80/TCP    20s

## obtenemos infomacion del servicio
kubectl describe svc clase4

# Name:              clase4
# Namespace:         clase4
# Labels:            app=clase4
# Annotations:       <none>
# Selector:          app=clase4
# Type:              ClusterIP
# IP Families:       <none>
# IP:                10.100.236.78
# IPs:               10.100.236.78
# Port:              <unset>  80/TCP
# TargetPort:        80/TCP
# Endpoints:         192.168.15.148:80,192.168.18.124:80
# Session Affinity:  None
# Events:            <none>

## Eliminamos el servicio 
kubectl -n clase4 delete svc clase4
```

### Ejemplo NodePort

En este caso vamos a probar **NodePort** el cual va a asignar el IP de los worker nodes y un puerto espesifico asociado al servicio, pero tambien se asignara un ClusterIP al servicio.

```shell
# creamos el servicio
kubectl apply -f https://raw.githubusercontent.com/dolguin-/aws101-kubernetes/clase-4/clase-4/03-service_nodeport.yaml

# chequeamos que este aplicado
kubectl -n clase4 get svc
# NAME     TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
# clase4   NodePort   10.100.194.19   <none>        80:30133/TCP   11s


## obtenemos infomacion del servicio
kubectl -n clase4 describe svc clase4
# Name:                     clase4
# Namespace:                clase4
# Labels:                   app=clase4
# Annotations:              <none>
# Selector:                 app=clase4
# Type:                     NodePort
# IP Families:              <none>
# IP:                       10.100.194.19
# IPs:                      10.100.194.19
# Port:                     <unset>  80/TCP
# TargetPort:               80/TCP
# NodePort:                 <unset>  30133/TCP
# Endpoints:                192.168.15.148:80,192.168.18.124:80
# Session Affinity:         None
# External Traffic Policy:  Cluster
# Events:                   <none>

## Eliminamos el servicio 
kubectl -n clase4 delete svc clase4

```

### Ejemplo Load Balancer

En este ejmplo vamos a exporner el servicio por medio de un load balancer, el cloud controler manger va a solicitar a AWS que cree el load balancer, security group, target group y va a registrar las instancias de los worker nodes relacionadas, para esto va a utilizar un NodePort para  exponer el servicio por medio de los IP y un puerto y tambien va a generar un ClusterIP para enrutar internamente el trafico.
Como este ejemplo requiere la creacion de un load balancer tener en cuetna que va a tardar un buen tiempoe generarse.

```shell

# creamos el servicio
kubectl apply -f https://raw.githubusercontent.com/dolguin-/aws101-kubernetes/clase-4/clase-4/04-service_LoadBalancer.yaml

# chequeamos que este aplicado
kubectl -n clase4 get svc
# NAME     TYPE           CLUSTER-IP      EXTERNAL-IP                                                              PORT(S)        AGE
# clase4   LoadBalancer   10.100.80.205   acb183b32d4694335bbc9c65deec214e-877451066.us-east-1.elb.amazonaws.com   80:32734/TCP   4m

## obtenemos infomacion del servicio
kubectl -n clase4 describe svc clase4
# Name:                     clase4
# Namespace:                clase4
# Labels:                   app=clase4
# Annotations:              <none>
# Selector:                 app=clase4
# Type:                     LoadBalancer
# IP Families:              <none>
# IP:                       10.100.80.205
# IPs:                      10.100.80.205
# LoadBalancer Ingress:     acb183b32d4694335bbc9c65deec214e-877451066.us-east-1.elb.amazonaws.com
# Port:                     <unset>  80/TCP
# TargetPort:               80/TCP
# NodePort:                 <unset>  32734/TCP
# Endpoints:                192.168.15.148:80,192.168.18.124:80
# Session Affinity:         None
# External Traffic Policy:  Cluster
# Events:
#   Type    Reason                Age    From                Message
#   ----    ------                ----   ----                -------
#   Normal  EnsuringLoadBalancer  3m52s  service-controller  Ensuring load balancer
#   Normal  EnsuredLoadBalancer   3m49s  service-controller  Ensured load balancer

## Eliminamos el servicio 
kubectl -n clase4 delete svc clase4

```

### Ejemplo External Name

<!-- TODO: completar descipcion -->

```shell

# creamos el servicio
kubectl apply -f https://raw.githubusercontent.com/dolguin-/aws101-kubernetes/clase-4/clase-4/05-service_ExternalName.yaml

# chequeamos que este aplicado
kubectl -n clase4 get svc
# NAME     TYPE           CLUSTER-IP   EXTERNAL-IP          PORT(S)   AGE
# clase4   ExternalName   <none>       hola.aws101.org   <none>    6s

## obtenemos infomacion del servicio
kubectl -n clase4 describe svc clase4
# Name:              clase4
# Namespace:         clase4
# Labels:            app=clase4
# Annotations:       <none>
# Selector:          <none>
# Type:              ExternalName
# IP Families:       <none>
# IP:                
# IPs:               <none>
# External Name:     db.prod.aws101.org
# Session Affinity:  None
# Events:            <none>

## Eliminamos el servicio 
kubectl -n clase4 delete svc clase4
```

## Remover los recursos

Una ves que terminen de realizar las practicas no se olviden de remover todos los recuros para no generar gastos no experados.

```shell
eksctl delete cluster -f aws101-cluster.yaml 
# 2021-08-01 00:58:22 [ℹ]  eksctl version 0.55.0
# 2021-08-01 00:58:22 [ℹ]  using region us-east-1
# 2021-08-01 00:58:22 [ℹ]  deleting EKS cluster "aws101"
# 2021-08-01 00:58:25 [ℹ]  deleted 0 Fargate profile(s)
# 2021-08-01 00:58:27 [ℹ]  cleaning up AWS load balancers created by Kubernetes objects of Kind Service or Ingress
```

## Autor

Damian A. Gitto Olguin
AWS Community Hero
@enlink / @teracloudio
https://teracloud.io
