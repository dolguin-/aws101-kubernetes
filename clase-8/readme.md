# Secrets

- [Secrets](#secrets)
  - [Definición](#definición)
  - [Formas de Crear un Secret](#formas-de-crear-un-secret)
    - [Desde un archivo](#desde-un-archivo)
    - [Desde la línea de comando (literal)](#desde-la-línea-de-comando-literal)
    - [Desde una Yaml manifest](#desde-una-yaml-manifest)
  - [cómo acceder a un secreto](#cómo-acceder-a-un-secreto)
  - [Práctica](#práctica)
    - [Preparación](#preparación)
    - [Verificamos la configuración](#verificamos-la-configuración)
    - [Otras maneras de crear se secretos](#otras-maneras-de-crear-se-secretos)
  - [Remover los recursos](#remover-los-recursos)
  - [Disclaimer](#disclaimer)
  - [Referencias](#referencias)
  - [Autor](#autor)

## Definición

Los Secretos en Kubernetes proveen una solución para almacenar información sensible y confidencial, como por ejemplo contraseñas, api keys, ssh keys, tokens, etc.

Los secretos ponen la información confidencial a disposición del Pod que los necesita y proveen mayor control sobre cómo se usa la información allí almacenada reduciendo (pero no eliminando) el riesgo de que esta información sea expuesta accidentalmente.

Los secretos pueden ser creados por el usuario o por el sistema.

ref: [Documentación oficial](https://kubernetes.io/es/docs/concepts/configuration/secret/)

## Formas de Crear un Secret

### Desde un archivo

Un secreto puede ser creado cargando directamente del contenido de un archivo para ello se utiliza el comando `kubectl` de la siguiente manera:

```shell
kubectl create secret generic db-user-pass \
  --from-file=./username.txt \
  --from-file=./password.txt
Secret "db-user-pass" created
```

Donde `username.txt` contiene el valor del usuario y `password.txt` tiene el valor del password.

### Desde la línea de comando (literal)

Si deseas crear un secreto directamente de la línea de comando ten en cuenta que el valor puede quedar en el historial de tu terminal así que toma los recaudos necesarios para no exponer ningún dato sensible.

```shell
kubectl create Secret generic dev-db-secret \
 --from-literal=username=devuser \
 --from-literal=password='S\!B*d$zDsb'
```

Otra cosa a considerar cuando utilizamos este método es utilizar `'` para delimitar el valor del secreto o escapar utilizando `\`

### Desde una Yaml manifest

Los secretos como la mayoría de los objetos de k8s se pueden crear desde manifestos en formato yaml entre otros, para ello deberás codificar el valor del secreto en base64.

```yaml
apiVersion: v1
kind: Secret
metadata:
 name: mysecret
type: Opaque
data:
 username: YWRtaW4=
 password: MWYyZDFlMmU2N2Rm
```

también es posible hacer que un secreto genere un archivo de configuración al igual que lo hacen los ConfigMaps para ello deberás definirlo utilizando `stringData` y en la siguiente línea el nombre del archivo que va a generar en lugar de `data`, de la siguiente manera:

```yaml
apiVersion: v1
kind: Secret
metadata:
 name: mysecret
type: Opaque
stringData:
 config.yaml: |-
   apiUrl: "https://my.api.com/api/v1"
   username: {{username}}
   password: {{password}}
```

Esto es muy útil cuando tenemos aplicaciones que poseen configuraciones basadas en archivos en lugar de utilizar variables de entorno.

## cómo acceder a un secreto

- Listar secretos

  `kubectl get secrets`

  ```shell
  NAME                  TYPE                                  DATA      AGE
  db-user-pass          Opaque                                2         51s
  ```

- Obtener detalles del secreto

  `kubectl describe secrets/db-user-pass`

  ```shell
  Name:            db-user-pass
  Namespace:       default
  Labels:          <none>
  Annotations:     <none>

  Type:            Opaque

  Data
  ====
  password.txt:    12 bytes
  username.txt:    5 bytes
  ```

  **Importante**: `kubectl get` y `kubectl describe` no muestran el contenido de un Secreto por defecto para prevenir la exposición accidental a cualquiera que esté mirando tu pantalla o que termine en algún log de tu terminal.

## Práctica

En esta clase vamos a realizar un ejercicio más similar a la vida real, vamos a desplegar un stack completo para correr wordpress incluyendo la base de datos tal y como la desplegamos en la clase anterior.
Todo lo realizaremos en el namespace `clase8` y los yamls para crear los siguientes componentes:

- Storage Class
- PVC para mariaDB
- PVC para wordpress
- Secrets para mariaDB
- Secrets para wordpress
- Deployment de MariaDB
- Service para MariaDB
- Deployment de Wordpress
- Service para Wordpress

Como verán este caso es mucho más completo que los que hemos realizado anteriormente por esta razón realizaremos el apply de una forma que aplique todos los Yamls contenidos en el directorio de trabajo `clase-8`

Como pre-requisito deberán clonar el repositorio del curso e ingresar a la carpeta `clase-8/`

### Preparación

- Aplicamos todos los manifests de la siguiente manera

  `kubectl apply -f .`

  ```shell
  cd clase-8
  kubectl apply -f .
  # namespace/clase8 created
  # persistentvolumeclaim/mariadb-data-disk created
  # persistentvolumeclaim/wp-pv-claim created
  # secret/mariadb-secrets created
  # deployment.apps/mariadb created
  # service/mariadb created
  # deployment.apps/wordpress created
  # service/wordpress created
  ```

### Verificamos la configuración

Una vez aplicados los cambios vamos a revisar que todas las cargas de trabajo se encuentren correctamente desplegadas.

- Verificamos los pvc
- Verificamos los deployments
- Verificamos los servicios
- Verificamos los secretos dentro de los pods

  Para verificar los secretos vamos a ingresar a la línea de comandos del container utilizando `kubectl exec -it <<pod_-_name>> -- bash` de esta manera podremos acceder al contenedor que está corriendo, de una manera similar a lo que hacemos con `Docker exec`.

- ingresar al pod

  `kubectl -n clase8 get pods`
  `kubectl -n clase8 exec -it <<pod_-_name>> -- bash`
  Una vez dentro del pod imprimimos las variables de entorno ejecutando los siguientes comandos:

  - `env | grep MARIADB_` para el Pod de mariadb
  - `env |grep WORDPRESS_DB` para el Pod de wordpress

  ```shell
  kubectl -n clase8 get pods
  #NAME                        READY   STATUS    RESTARTS   AGE
  #mariadb-5c6df5699d-gdxh6    1/1     Running   0          6m48s
  #wordpress-bc94769fd-bww69   1/1     Running   0          6m46s

  kubectl -n clase8 exec -it  mariadb-5c6df5699d-gdxh6 -- bash

  root@mariadb-5c6df5699d-gdxh6:/# env | grep MARIADB_
  # MARIADB_USER=user
  # MARIADB_DATABASE=aws101
  # MARIADB_VERSION=1:10.6.4+maria~focal
  # MARIADB_MAJOR=10.6
  # MARIADB_USER_PASSWORD=user
  # MARIADB_ROOT_PASSWORD=root

  kubectl -n clase8 exec -it wordpress-bc94769fd-bww69 -- bash
  root@wordpress-bc94769fd-bww69:/var/www/html# env |grep WORDPRESS_DB
  # WORDPRESS_DB_HOST=mariadb
  # WORDPRESS_DB_PASSWORD=root
  # WORDPRESS_DB_USER=root
  # WORDPRESS_DB_NAME=aws101
  ```

  Aquí podremos apreciar que nuestro secretos se encuentran entre las variables de entorno de nuestros Pod.
  Cabe aclarar que los secretos se comportan de una manera similar a los ConfigMaps, cuando son actualizados es necesario reemplazar nuestros pods para que vuelvan a cargar las variables de entorno en tanto que para los archivos no es necesario.

### Otras maneras de crear se secretos

- también es posible crear un secreto de manera literal en la línea de comando

  para crear el secreto de manera literal utilizaremos el comando

  `kubectl -n clase8 create secret generic mi-secret --from-literal=username=devuser --from-literal=password='S\!B*d$zDsb'`

- chequeamos que este aplicado

  `kubectl -n clase8 get secrets db-secret`

  ```shell
  NAME        TYPE     DATA   AGE
  mi-secret   Opaque   2      24m
  ```

- describimos verificamos el secreto api-config

  `kubectl -n clase8 describe secret mi-config`

  ```shell
  Name:         mi-secret
  Namespace:    clase8
  Labels:       <none>
  Annotations:  <none>

  Type:  Opaque

  Data
  ====
  password:  8 bytes
  username:  7 bytes
  ```

  Aquí podemos ver que nos muestra las keys que componen el secreto pero no los valores de cada uno.

## Remover los recursos

Una vez que terminen de realizar las prácticas no se olviden de remover todos los recursos para no generar gastos no esperados.

`kubectl delete ns clase8`

```shell
eksctl delete cluster -f aws101-cluster.yaml
# 2021-08-01 00:58:22 [ℹ]  eksctl version 0.55.0
# 2021-08-01 00:58:22 [ℹ]  using region us-east-1
# 2021-08-01 00:58:22 [ℹ]  deleting EKS cluster "aws101"
# 2021-08-01 00:58:25 [ℹ]  deleted 0 Fargate profile(s)
# 2021-08-01 00:58:27 [ℹ]  cleaning up AWS load balancers created by Kubernetes objects of Kind Service or Ingress
```

## Disclaimer

Para realizar las prácticas no es necesario utilizar un cloud provider, la mayoria de las practicas se pueden realizar en [Play With K8s](https://labs.play-with-k8s.com/), de todas maneras para algunas prácticas relacionadas con componentes que solo están disponibles en un cloud provider es preferible que sea en un cloud provider como AWS, GCP o Azure.
El participante es 100% responsable de los costos generados al realizar las prácticas, desde este espacio renunciamos a toda responsabilidad por costos generados al realizar los laboratorios.
Les pedimos que sean conscientes de remover todos los recursos utilizados cuando finalicen las prácticas.

## Referencias

[1] [Documentacion de kubernetes - Secretos](https://kubernetes.io/es/docs/concepts/configuration/secret/)

## Autor

Damian A. Gitto Olguin
[AWS Community Hero](https://www.youtube.com/c/damianolguinAWSHERO)
[@enlink](https://twitter.com/enlink)] / [@teracloudio](https://twitter.com/teracloudio)
<https://teracloud.io>
