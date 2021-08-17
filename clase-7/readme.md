# Volumenes Persistentes

- [Volumenes Persistentes](#volumenes-persistentes)
  - [Definición](#definición)
    - [PersistentVolume (PV)](#persistentvolume-pv)
    - [PersistentVolumeClaim (PVC)](#persistentvolumeclaim-pvc)
  - [Ciclo de Vida](#ciclo-de-vida)
    - [Provisioning](#provisioning)
      - [Estático](#estático)
      - [Dinámico](#dinámico)
  - [Tipos](#tipos)
  - [PV Manifest](#pv-manifest)
  - [PVC Manifest](#pvc-manifest)
  - [Claims como Volumen](#claims-como-volumen)
  - [Práctica](#práctica)
    - [Verificamos la configuración](#verificamos-la-configuración)
  - [Remover los recursos](#remover-los-recursos)
  - [Disclaimer](#disclaimer)
  - [Referencias](#referencias)
  - [Autor](#autor)

## Definición

En la clase anterior hablamos de Volúmenes, en esta clase vamos a hablar de administrar Volúmenes persistentes.
El subsistema `PersistentVolume` provee una API que abstrae detalles del tipo *como a provisionar almacenamiento hasta cómo es consumido*, para ello se introducen dos objetos `PersistentVolume` y `PersistentVolumeClaim`.

### PersistentVolume (PV)

`PersistentVolume` es una pieza de almacenamiento en el cluster que ya ha sido provisionada por un administrador o provisionada dinámicamente usando `Storage Classes`. Es simplemente un recurso más de un cluster como lo es un `worker node` por ejemplo. Los `PV`s son plugins como los volúmenes, pero con un ciclo de vida independiente del Pod que lo utiliza, puede ser NFS, iSCSI o un volumen provisionado en el cloud provider a través del CCM.

### PersistentVolumeClaim (PVC)

Un `PersistentVolumeClaim` de ahora en más `PVC` es un requerimiento de almacenamiento. Es similar a un Pod que consume recursos en un worker node, el `PVC` consume recursos `PV`.
Así como los Pod pueden solicitar recursos específicos como CPU y Memoria un Claim puede requerir recursos específicos como tamaño y modo de acceso.

Mientras que los PVC permiten al usuario consumir recursos de almacenamiento de manera abstracta, es común que los usuarios necesiten PV con variadas propiedades dependiendo de sus necesidades/problemas como por ejemplo performance +/- IOPS, read-only, filesystem compartidos, etc, los administradores necesitan la posibilidad de ofrecer variedades de PV para cumplir con estas demandas sin exponer detalles de cómo estos volúmenes son implementados a los usuarios. Para esto existe el recurso `StorageClass`.

ref: [Persistent Volumes](#Referencias)

## Ciclo de Vida

- Provisioning
- Binding
- Using
- In-Use Protection
- Re-Claiming
- Reserving
- Expanding
- Delete

### Provisioning

El aprovisionamiento de los PV  puede ser dinámico o estático.

#### Estático

Es similar a lo que vimos en la [clase 6](../clase-6/readme.md), el administrador del cluster crea cierta cantidad de `PVs` y los pone a disposición de los usuarios a través de la API de K8s.

#### Dinámico

En el caso de que el `PVC` no concuerde con ningún `PV` el cluster intentara provisionar automáticamente un volumen para este `PVC`, a esta tarea la llevará a cabo basándose en los `StorageClasses`, el PVC deberá requerir un `storage class`, este deberá estar pre-definido por el administrador para provisionamiento dinámico.

Si el `PVC` tiene definido cómo `StorageClass` `""` esto deshabilita el provisionamiento dinámico para sí mismo.

## Tipos

Los tipos de PersistentVolume son implementados como plugins. Kubernetes actualmente soporta  los siguientes plugins:

- awsElasticBlockStore - AWS Elastic Block Store (EBS)
- azureDisk - Azure Disk
- azureFile - Azure File
- cephfs - CephFS volume
- csi - Container Storage Interface **(CSI)**
- fc - Fibre Channel (FC)
- flexVolume - FlexVolume
- gcePersistentDisk - GCE Persistent Disk
- glusterfs - Glusterfs
- hostPath - ruta definida en el nodo anfitrión (solo para un clusters de un nodo)
- iscsi - iSCSI (SCSI sobre IP)
- local - unidades locales montadas en los nodos.
- nfs - Network File System (NFS)
- portworxVolume - Portworx
- rbd - Rados Block Device (RBD)
- vsphereVolume - vSphere VMDK

## PV Manifest

Cada PV contiene una `spec` y un `status`, que son la especificación y el estado del volumen. El nombre de un objeto `PersistentVolume` debe ser un nombre de [subdominio DNS válido - RFC 1123.](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#dns-subdomain-names)

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
 name: pv0003
spec:
 capacity:
   storage: 5Gi
 volumeMode: Filesystem
 accessModes:
   - ReadWriteOnce
 persistentVolumeReclaimPolicy: Recycle
 storageClassName: slow
 mountOptions:
   - hard
   - nfsvers=4.1
 nfs:
   path: /tmp
   server: 172.17.0.2
```

## PVC Manifest

Cada `PVC` contiene una `spec` y un `status`, que son la especificación y el estado del `claim`. El nombre de un `PersistentVolumeClaim` tiene que ser un nombre de [subdominio DNS valido - RFC 1123.](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#dns-subdomain-names)

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
 name: myclaim
spec:
 accessModes:
   - ReadWriteOnce
 volumeMode: Filesystem
 resources:
   requests:
     storage: 8Gi
 storageClassName: slow
 selector:
   matchLabels:
     release: "stable"
   matchExpressions:
     - {key: environment, operator: In, values: [dev]}
```

## Claims como Volumen

Pods acceder al almacenamiento usando `Claims` como volumen. Para esto el `Claim` debe existir en el mismo namespace que existe el Pod. El Cluster buscará el claim en el namespace del Pod y lo utilizara para obtener el `PersistentVolume` que soporta a ese `claim`. Luego el volumen es montado en el host donde corre el Pod y dentro del Pod también.

```yaml
apiVersion: v1
kind: Pod
metadata:
 name: mypod
spec:
 containers:
   - name: myfrontend
     image: nginx
     volumeMounts:
     - mountPath: "/var/www/html"
       name: mypd
 volumes:
   - name: mypd
     persistentVolumeClaim:
       claimName: myclaim
```

## Práctica

En esta clase vamos a desplegar una base de datos MariaDB, para ello vamos a crear el namespace `clase7`, vamos a crear un `PVC` y luego utilizando un `deployment` vamos a lanzar nuestra base de datos.

Lo primero que vamos a hacer para este práctico es crear el namespace

- Aplicamos el manifest que crea nuestro namespace

  `kubectl apply -f https://raw.githubusercontent.com/dolguin-/aws101-kubernetes/main/clase-7/00-namespace.yaml`

- Creamos el Secret que contendrá las claves de administrador y usuario de nuestra db

  `kubectl apply -f https://raw.githubusercontent.com/dolguin-/aws101-kubernetes/main/clase-7/01-secret.yaml`

- Aplicamos el manifest para crear nuestro PersitentVolumeClaim

  `kubectl apply -f https://raw.githubusercontent.com/dolguin-/aws101-kubernetes/main/clase-7/02-pvc.yaml`

- Controlamos que nuestro Claim se encuentra listo

  `kubectl -n clase7 get pvc`

  ```shell
  NAME                STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
  mariadb-data-disk   Pending                                      gp2            2s
  ```

  `kubectl -n clase7 describe pvc`

  ```shell
  Name:          mariadb-data-disk
  Namespace:     clase7
  StorageClass:  gp2
  Status:        Pending
  Volume:
  Labels:        <none>
  Annotations:   <none>
  Finalizers:    [kubernetes.io/pvc-protection]
  Capacity:
  Access Modes:
  VolumeMode:    Filesystem
  Used By:       <none>
  Events:
    Type    Reason                Age               From                         Message
    ----    ------                ----              ----                         -------
    Normal  WaitForFirstConsumer  5s (x3 over 33s)  persistentvolume-controller  waiting for first consumer to be created before binding
  ```

  *Los volúmenes serán creados cuando sean reclamados por primera vez por un Pod.*

- creamos el Deployment de nuestra DB

  `kubectl apply -f https://raw.githubusercontent.com/dolguin-/aws101-kubernetes/main/clase-7/03-mariadb.yaml`

- chequeamos que este aplicado

  `kubectl -n clase7 get deployment`

  ```shell
  NAME      READY   UP-TO-DATE   AVAILABLE   AGE
  mariadb   1/1     1            1           41s
  ```

  Una vez aplicados estos cambios estamos listos para verificar que el pod asignado a nuestro deployment contiene el volumen montado y la base corriendo.

### Verificamos la configuración

Para verificar el volumen vamos a ingresar a la línea de comandos del container utilizando `kubectl exec -it <<pod_-_name>> -- bash` de esta manera podremos acceder al contenedor que está corriendo, de una manera similar a lo que hacemos con `Docker exec`.

- Obtenemos el nombre del **pod**

  `kubectl -n clase7 get pods`

  ```shell
  NAME                     READY   STATUS    RESTARTS   AGE
  mariadb-84687fddbf-6f9tp   1/1     Running   0          126s
  ```

- ingresamos al pod

  `kubectl -n clase7 exec -it mariadb-84687fddbf-6f9tp -- bash`

  ```shell
  root@mariadb-84687fddbf-6f9tp:/#
  ```

  Una vez dentro del pod imprimimos las variables de entorno ejecutando los siguientes comandos

  `df -h`

  ```shell
  root@mariadb-84687fddbf-6f9tp:/# df -h
  Filesystem      Size  Used Avail Use% Mounted on
  ........
  ........
  shm              64M     0   64M   0% /dev/shm
  #/dev/nvme1n1    9.8G  169M  9.6G   2% /var/lib/mysql
  tmpfs           975M   12K  975M   1% /run/secrets/kubernetes.io/serviceaccount
  ........
  ```

- nos conectaremos a la base de datos para interactuar

  `mysql -u root -p`

  *cuando lo solicite ingresar el password `root`*
    una vez dentro de mysql crearemos una nueva DB llamada **MY_APP**

  ```shell
  root@mariadb-84687fddbf-6f9tp:/# mysql -u root -p
  Enter password:
  Welcome to the MariaDB monitor.  Commands end with ; or \g.
  Your MariaDB connection id is 3
  Server version: 10.6.4-MariaDB-1:10.6.4+maria~focal mariadb.org binary distribution

  Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

  Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.
  MariaDB [(none)]> create database MY_APP;
  Query OK, 1 row affected (0.000 sec)
  ```

- Probaremos la persistencia eliminaremos el Pod

  `kubectl -n clase7 delete pod mariadb-84687fddbf-6f9tp`

  Una vez eliminado el pod, al notar la diferencia nuestro deployment lanzará un nuevo Pod.

  `kubectl -n clase7 get pods`

  ```shell
  NAME                       READY   STATUS    RESTARTS   AGE
  mariadb-84687fddbf-gsqqx   1/1     Running   0          33s
  ```

- Verificamos que nuestros datos persistieron a la eliminación del pod

  `kubectl -n clase7 exec -it mariadb-84687fddbf-gsqqx  -- mysql -u root -p`

  ```shell
  Enter password:
  Welcome to the MariaDB monitor.  Commands end with ; or \g.
  Your MariaDB connection id is 3
  Server version: 10.6.4-MariaDB-1:10.6.4+maria~focal mariadb.org binary distribution
  Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.
  Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

  MariaDB [(none)]> show databases;
  +---------------------+
  | Database            |
  +---------------------+
  | MY_APP              |
  | aws101              |
  | information_schema  |
  | mysql               |
  | performance_schema  |
  | sys                 |
  +---------------------+
  7 rows in set (0.001 sec)
  MariaDB [(none)]>
  ```

  Aquí podremos ver que la base de datos que hemos creado está disponible en la lista de bases de datos lo que comprueba la persistencia del volumen por sobre el ciclo de vida del Pod.

## Remover los recursos

Una vez que terminen de realizar las prácticas no se olviden de remover todos los recursos para no generar gastos no esperados.

`kubectl delete ns clase7`

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

[1] [Documentacion de kubernetes - Volumens Persistentes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)

## Autor

Damian A. Gitto Olguin
[AWS Community Hero](https://www.youtube.com/c/damianolguinAWSHERO)
[@enlink](https://twitter.com/enlink)] / [@teracloudio](https://twitter.com/teracloudio)
<https://teracloud.io>
