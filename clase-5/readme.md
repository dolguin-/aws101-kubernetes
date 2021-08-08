# ConfigMap

- [ConfigMap](#configmap)
  - [Definicion](#definicion)
  - [Motivo](#motivo)
  - [Objecto ConfigMap](#objecto-configmap)
  - [Formas de Utilizar ConfigMap](#formas-de-utilizar-configmap)
  - [Práctica](#práctica)
    - [Preparación](#preparación)
    - [Creamos el ConfigMap](#creamos-el-configmap)
    - [Verificamos la configuracion](#verificamos-la-configuracion)
  - [Remover los recursos](#remover-los-recursos)
  - [Disclaimer](#disclaimer)
  - [Referencias](#referencias)
  - [Autor](#autor)

## Definicion

Un configmap es un objeto de kubernetes utilizado para **almacenar datos no confidenciales** en el formato clave-valor. Los Pods pueden utilizar los ConfigMaps como variables de entorno, argumentos de la linea de comandos o como ficheros de configuración en un Volumen.

Un ConfigMap te permite desacoplar la configuración de un entorno específico de una imagen de contenedor, así las aplicaciones son fácilmente portables. [1]

## Motivo

Utiliza un ConfigMap para crear una configuración separada del código de la aplicación.
Por ejemplo, imagina que estás desarrollando una aplicación que puedes correr en tu propio equipo (como ambiente de desarrollo) y en la nube (como ambiente de produccion), entonces escribes el código para configurar la base de datos utilizando una variable llamada DATABASE_HOST, de esta manera en tu equipo configuras la variable con el valor localhost, mientras que en en el cloud, la configuras con referencia a una instancia RDS contiene la base de datos dentro de tu VPC.

Esto permite tener la misma compilacion de tu codigo corriendo en todos los ambientes, y de esta manera mantener concistencia.

## Objecto ConfigMap

El Objeto ConfigMap a diferencia de otros objetos en kubernetes que tiene una seccion `spec` tiene una seccion `data` donde espesificaremos el contenido del mismo

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws101-config
data:
  # Clave-Valor; cada Clave (key) esta asignada a un valor (value) simple
  PORT: "80"
  DATABASE_HOST: "db.aws101.org"
  # Archivos como Clave(key)
  environment.properties: |
    PORT=80
    DATABASE_HOST=db.aws101.org
```

## Formas de Utilizar ConfigMap

Hay cuatro maneras diferentes de usar un ConfigMap para configurar un contenedor dentro de un Pod:

1. Argumento en la linea de comandos como entrypoint de un contenedor.
1. Variable de entorno de un contenedor.
1. Como fichero en un volumen de solo lectura, para que lo lea la aplicación.
1. Escribir el código para ejecutar dentro de un Pod que utiliza la API para leer el ConfigMap.

## Práctica

Para esta clase vamos a crear el namespace `clase5` luego vamos a Crear nuestro config map y lo consumiremos desde nuestra aplicación `hola-aws101` que desplegaremos a través de un `deployment` llamado `clase5`.

### Preparación

  Lo primero que vamos a hacer para este practico es crear el namespace

- Aplicamos el manifest que crea nuestro namespace

  `kubectl apply -f https://raw.githubusercontent.com/dolguin-/aws101-kubernetes/main/clase-5/00-namespace.yaml`

### Creamos el ConfigMap

- Aplicamos el manifest que crea nuestro ConfigMap

  `kubectl apply -f https://raw.githubusercontent.com/dolguin-/aws101-kubernetes/main/clase-5/01-configmap.yaml`

- Verificamos que fue creado

  `$ kubectl -n clase5 get configmap aws101-config`

  ```shell
  NAME            DATA   AGE
  aws101-config   3      6m53s
  ```

- Visualizamos el contenido usando Describe:

  `kubectl -n clase5 describe configmap aws101-config`

  ```shell
  Name:         aws101-config
  Namespace:    clase5
  Labels:       app=clase5
  Annotations:  <none>

  Data
  ====
  DATABASE_HOST:
  ----
  db.aws101.org
  NGINX_PORT:
  ----
  80
  default.conf:
  ----
  server {
  ......
  ......
  }
  Events:  <none>
  ```

- Visualizamos el contenido en formato Yaml:

  `kubectl -n clase5 get configmaps aws101-config -o yaml`

  ```shell
  apiVersion: v1
  data:
    DATABASE_HOST: db.aws101.org
    NGINX_PORT: "80"
    default.conf: |
      server {
        listen       80;
        server_name  localhost;

        location / {
            root   /usr/share/nginx/html;
            index  index.html index.htm;
  .............
  .............
  .............
  ```

  Ahora que tenemos nuestro ambiente preparado pasamos a provar las distintas formas de consumir un **ConfigMap**

- Aplicamos el manifest que despliega nuestro deployment

  `kubectl apply -f https://raw.githubusercontent.com/dolguin-/aws101-kubernetes/main/clase-5/02-deployment.yaml`

- Controlamos que nuestro deployment ya este listo

  `kubectl -n clase5 get deployment`

  ```shell
  # NAME     READY   UP-TO-DATE   AVAILABLE   AGE
  # clase5   2/2     2            2           102m
  ```

  `kubectl -n clase5 describe deployment clase5`

  ```shell
  # Name:                   clase4
  # Namespace:              clase4
  # CreationTimestamp:      Sat, 31 Jul 2021 21:17:31 -0300
  # Labels:                 app=clase4
  # Annotations:            deployment.kubernetes.io/revision: 1
  ......
  ......
  ```

- creamos el Servicio

  `kubectl apply -f https://raw.githubusercontent.com/dolguin-/aws101-kubernetes/main/clase-5/03-service.yaml`

- chequeamos que este aplicado

  `kubectl -n clase5 get svc`

  ```shell
  NAME     TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)        AGE
  clase5   LoadBalancer   10.96.47.99   172.19.255.200   80:30247/TCP   10s
  ```

  Una vez aplicados estos cambios estamos listos para verificar que nuestro deployment contiene las configuraciones que le agregamos via configmap.

### Verificamos la configuracion

Para verificar las configuraciones vamos a ingresar a la linea de comandos del container utilizando `kubectl exec -it <<pod_-_name>> -- bash` de esta manera podermos acceder al container que esta corriendo, de una manera similar a lo que hacemos con `Docker exec`.

- Obtenemos el nombre del **pod**

  `kubectl -n clase5 get pods`

  ```shell
  NAME                     READY   STATUS    RESTARTS   AGE
  clase5-96996ccd9-pvbgt   1/1     Running   0          17m
  clase5-96996ccd9-zjnls   1/1     Running   0          17m
  ```

- ingrasamos a uno de los pods

  `kubectl -n clase5 exec -it clase5-96996ccd9-pvbgt -- bash`

  ```shell
  root@clase5-96996ccd9-pvbgt:/#
  ```

  Una ves dentro del pod imprimimos las variables de entorno ejecutando los siguientes comandos

  `env |grep DATABASE`

  `env |grep NGINX_PORT`

  ```shell
  root@clase5-96996ccd9-pvbgt:/# env |grep DATABASE
  DATABASE_HOST=db.aws101.org
  root@clase5-96996ccd9-pvbgt:/# env |grep NGINX_PORT
  NGINX_PORT=80
  root@clase5-96996ccd9-pvbgt:/# exit
  ```

- Verificamos de Configuracion

  Para verificar que nuestro **Pod** posee la configuracion que agregamos en nuestro configmap vamos a dirigirnos al directorio donde montamos el volument con la configuracion y vamos a verificar el contenido utilizando los siguientes comandos

  `cd /etc/nginx/conf.d/`

  `cat default.conf`

  ```shell
  root@clase5-6499665b84-rj7td:/# cd /etc/nginx/conf.d/
  root@clase5-6499665b84-rj7td:/etc/nginx/conf.d# ls
  default.conf
  root@clase5-6499665b84-rj7td:/etc/nginx/conf.d# cat default.conf
  server {
    listen  80;
    listen  [::]:80;
    server_name  localhost;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

    add_header Cache-Control "no-cache, no-store";

  }
  root@clase5-6499665b84-rj7td:/etc/nginx/conf.d# exit
  ```

## Remover los recursos

Una vez que terminen de realizar las prácticas no se olviden de remover todos los recursos para no generar gastos no esperados.

```shell
eksctl delete cluster -f aws101-cluster.yaml
# 2021-08-01 00:58:22 [ℹ]  eksctl version 0.55.0
# 2021-08-01 00:58:22 [ℹ]  using region us-east-1
# 2021-08-01 00:58:22 [ℹ]  deleting EKS cluster "aws101"
# 2021-08-01 00:58:25 [ℹ]  deleted 0 Fargate profile(s)
# 2021-08-01 00:58:27 [ℹ]  cleaning up AWS load balancers created by Kubernetes objects of Kind Service or Ingress
```

## Disclaimer

Para realizar las practicas no es necesario utilizar un cloud provider, la mayoria de las practicas se pueden realizar en [Play With K8s](https://labs.play-with-k8s.com/), de todas maneras para algunas practicas relacionadas con componentes que solo estan disponibles en un cloud provider es preferible que sea en un cloud provider como AWS, GCP o Azure.
El participante es 100% responsable de los costos generados para al realizar las practicas, desde este espacio renunciamos a toda responsabilidad por costos generados al realizar los laboratorios.
Les pedimos que sean concientes de remover todos los recursos utilizados cuando finalizen las practicas.

## Referencias

[1] [Documentacion de kubernetes - ConfigMap](https://kubernetes.io/es/docs/concepts/configuration/configmap/)

## Autor

Damian A. Gitto Olguin
[AWS Community Hero](https://www.youtube.com/c/damianolguinAWSHERO)
[@enlink](https://twitter.com/enlink)] / [@teracloudio](https://twitter.com/teracloudio)
<https://teracloud.io>
