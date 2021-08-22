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
    - [Creacion de los secretos](#creacion-de-los-secretos)
  - [Remover los recursos](#remover-los-recursos)
  - [Disclaimer](#disclaimer)
  - [Referencias](#referencias)
  - [Autor](#autor)

## Definición

Los Secretos en Kubernetes proveen una solución para almacenar información sensible y confidencial, como por ejemplo contraseñas, api keys, ssh keys, tokens, etc.

Los secretos ponen la información confidencial a disposición del Pod que los necesita y proveen mayor control sobre cómo se usa la información allí almacenada reduciendo (pero no eliminando) el riesgo de que esta información sea expuesta accidentalmente.

Los secretos pueden ser creados por el usuario o por el sistema.

ref: [1 - Documentacion oficial](#Referencias)

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

En esta clase vamos realizar un ejercicio mas similar a la vida real, vamos a desplegar un stack completo para correr wordpress incluyendo la base de datos tal y como la desplegamos en la clase anterior.
Todo lo realizaremos en el namespace `clase8` y los yamls para crear los siguientes componenentes:

- Storage Class
- PVC para mariaDB
- PVC para wordpress
- Secrets para mariaDB
- Secrets para wordpress
- Deployment de MariaDB
- Service para MariaDB
- Deployment de Wordpress
- Service para Wordpress

Como veran este caso es mucho mas completo que los que hemos realizado anteriormente por esta razon realizaremos el apply de una forma que aplique todos los Yamls contenidos en el directorio de trabajo `clase-8`

### Preparación

 Lo primero que vamos a hacer para este práctico es crear el namespace

- Aplicamos el manifest que crea nuestro namespace

 `kubectl apply -f https://raw.githubusercontent.com/dolguin-/aws101-kubernetes/main/clase-6/00-namespace.yaml`

Una vez que tenemos nuestro namespace preparado pasamos a probar las distintas formas de crear secrets en k8s

### Creacion de los secretos

- creamos el primer secreto de manera literal

  para crear el secreto de manera literal utilizaremos el comando

  `kubectl -n clase8 create secret generic db-secret --from-literal=username=devuser --from-literal=password='S\!B*d$zDsb'`

  **(Opcional)** Si lo desean en lugar de hacerlo literal lo pueden hacer usando el yaml manifest de la siguiente manera:
    `kubectl apply -f https://raw.githubusercontent.com/dolguin-/aws101-kubernetes/main/clase-8/01-secret.yaml`

- chequeamos que este aplicado

  `kubectl -n clase8 get secrets db-secret`

  ```shell
  NAME        TYPE     DATA   AGE
  db-secret   Opaque   2      24m
  ```

- describimos verificamos el secreto api-config

  `kubectl -n clase8 describe secret api-config`

  ```shell
  Name:         db-secret
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

- Creamos el segundo secreto utilizando el yaml manifest

  `kubectl apply -f https://raw.githubusercontent.com/dolguin-/aws101-kubernetes/main/clase-8/02-secret.yaml`

- Chequeamos que este aplicado el segundo secreto

  `kubectl -n clase8 get secrets api-config`

  ```shell
  NAME         TYPE     DATA   AGE
  api-config   Opaque   1      26m
  ```

- Describimos verificamos el secreto api-config.

  `kubectl -n clase8 describe secret api-config`

  ```shell
  Name:         api-config
  Namespace:    clase8
  Labels:       <none>
  Annotations:  <none>

  Type:  Opaque

  Data
  ====
  config.yaml:  91 bytes
  ````

  Aquí podemos ver también que nos muestra la key que conforma el secreto que luego se convertirá en un archivo, pero no el contenido que contendrá el archivo.

### Verificamos la configuración

Una vez creados los secretos vamos a necesitar una carga de trabajo para poder consumirlos, en la clase de hoy vamos a utilizar un simple Pod.

- Desplegamos un Pod.

  `kubectl apply -f https://raw.githubusercontent.com/dolguin-/aws101-kubernetes/main/clase-8/03-pod.yaml`

  Para verificar los secrets vamos a ingresar a la línea de comandos del container utilizando `kubectl exec -it <<pod_-_name>> -- bash` de esta manera podremos acceder al contenedor que está corriendo, de una manera similar a lo que hacemos con `Docker exec`.

- ingresamos al pod

  `kubectl -n clase8 exec -it clase8 -- bash`

  ```shell
  root@clase8:/#
  ```

  Una vez dentro del pod imprimimos las variables de entorno ejecutando los siguientes comandos

  `env | grep DB_`

  ```shell
  # env|grep DB_
  DB_USERNAME=devuser
  DB_PASSWORD=S\!B*d$zDsb
  ```

  Aquí podremos apreciar que nuestro secreto se encuentra entre las variables de entorno de nuestro Pod.
  Cabe aclarar que los secretos se comportan de una manera similar a los ConfigMaps, cuando son actualizados es necesario reemplazar nuestros pods para que vuelvan a cargar las variables de entorno en tanto que para los archivos no es necesario.

- Verificamos los secrets en archivos

  `cd /mnt/api_config`

  `ls`

  `cat config.yaml`

  ```shell
  root@clase8:/# cd /mnt/api_config/
  root@clase8:/mnt/api_config# cat config.yaml

  apiUrl: "https://my.api.com/api/v1"
  username: apiTestUser
  password: PassWordSuperSecreto123

  ```

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
