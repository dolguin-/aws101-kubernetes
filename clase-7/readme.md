# Volumenes Persistentes

- [Volumenes Persistentes](#volumenes-persistentes)
  - [Definicion](#definicion)
    - [PersistentVolume (PV)](#persistentvolume-pv)
    - [PersistentVolumeClaim (PVC)](#persistentvolumeclaim-pvc)
  - [Ciclo de Vida](#ciclo-de-vida)
    - [Provisioning](#provisioning)
      - [Estatico](#estatico)
      - [Dinamico](#dinamico)
  - [Tipos](#tipos)
  - [PV Manifest](#pv-manifest)
  - [PVC Manifest](#pvc-manifest)
  - [Claims como Volumen](#claims-como-volumen)
  - [Práctica](#práctica)
    - [Verificamos la configuracion](#verificamos-la-configuracion)
  - [Remover los recursos](#remover-los-recursos)
  - [Disclaimer](#disclaimer)
  - [Referencias](#referencias)
  - [Autor](#autor)

## Definicion

En la clase anterior hablamos de Volumenes, en esta clase vamos a hablar de administrar Volumenes persistentes.
El subsistema `PersistentVolume` provee una API que abstrae detalles del tipo *como a provisionar almacenamiento hasta como es consumido*, para ello se introducen dos objetos `PersistentVolume` y `PersistentVolumeClaim`.

### PersistentVolume (PV)

`PersistentVolume` es una pieza de almacenamiento en el cluster que ya ha sido provisionada por un administrador o provisionada dinamicamente usando `Storage Classes`. Es simplemente un recurso mas de un cluster como lo es un `worker node` por ejemplo. Los `PV`s son plugins como los volumenes, pero con un ciclo de vida independiente del Pod que lo utiliza, puede ser NFS, iSCSI o un volumen provisionado en el cloud provider a travéz del CCM.

### PersistentVolumeClaim (PVC)

Un `PersistentVolumeClaim` de ahora en mas `PVC` es un requerimiento de almacenamiento. Es similar a un Pod que consume recursos en un worker node, el `PVC` consume recursos `PV`.
Asi como los Pod pueden solicitar recursos espesificos como CPU y Memoria un Claim puede requerir recursos especificos como tamaño y modo de acceso.

Mientras que los PVC permiten al usuario consumir recursos de almacenamiento de manera abstracta, es comuno que los usuarios necesiten PV con variadas propiedades dependiendo de sus necesidades/problemas como por ejemplo performance +/- IOPS, read-only, filesystem compartidos, etc, los administradores necesitan la posibilidad de ofrecer variedades de PV para cumplir con estas demandas sin exponer detalles de como estos volumenes son implementados a los usuarios. Para esto existe el recurso `StorageClass`.

ref: [Persistent Volumes](#Referencias)

## Ciclo de Vida

  Provisioning
  Binding
  Using
  In-Use Protection
  Re-Claiming
  Reserving
  Expanding
  Delete

### Provisioning

El aprovisionamiento de los PV  puede ser dinamico o estatico.

#### Estatico

Es similar a lo que vimos en la [clase 6](../clase-6/readme.md), el administrador del cluster crea cierta cantidad de `PVs` y los pone a dispocicion de los usuarios atravez de la API de K8s.

#### Dinamico

En el caso de que el `PVC` no concuerde con ningun `PV` el cluster intentara provicionar automaticamente un volument para este `PVC`, a esta tarea la llevara a cabo basandose en los `StorageClasses`, el PVC debera requerir un `storage class`, este debera estar pre-definido por el administrador para provisionamiento dinamico.

Si el `PVC` tiene tiene definido como `StorageClass` `""` esto desabilita el provisionamiento dinamico para si mismo.

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
- hostPath - ruta definicida en el nodo anfitrion (solo para un clusters de un nodo)
- iscsi - iSCSI (SCSI sobre IP)
- local - unidades locales montadas en los nodos.
- nfs - Network File System (NFS)
- portworxVolume - Portworx
- rbd - Rados Block Device (RBD)
- vsphereVolume - vSphere VMDK

## PV Manifest

Cada PV contiene una `spec` y un `status`, que son la especificacion y el estado del volument. El nombre de un objecto `PersistentVolume` debe ser un nombre de [subdominio DNS valido - RFC 1123.](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#dns-subdomain-names)

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

Cada `PVC` contiene una `spec` y un `status`, que son la espesificacion y el statdo del `claim`. El nombre de un `PersistentVolumeClaim` tiene que ser un nombre de [subdominio DNS valido - RFC 1123.](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/#dns-subdomain-names)

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

Pods acceden al almacenamiento usando `Claims` como volumen. Para esto el `Claim` debe existir en el mismo namespace que existe el Pod. El Cluster buscara el claim en el namespace del Pod y lo utilizara para obtener el `PersistentVolume` que soporta a ese `claim`. Luego el volumen es montado en el host donde corre el pode y dentro del pod tambien.

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

Lo primero que vamos a hacer para este practico es crear el namespace

- Aplicamos el manifest que crea nuestro namespace

  `kubectl apply -f https://raw.githubusercontent.com/dolguin-/aws101-kubernetes/main/clase-7/00-namespace.yaml`

- Aplicamos el manifest para crear nuestro PersitentVolumeClaim

  `kubectl apply -f https://raw.githubusercontent.com/dolguin-/aws101-kubernetes/main/clase-5/01-pod.yaml`

- Controlamos que nuestro pod ya este listo

  `kubectl -n clase6 get pods`

  ```shell
  NAME     READY   STATUS    RESTARTS   AGE
  clase6   1/1     Running   0          61s
  ```

  `kubectl -n clase6 describe pod clase6`

  ```shell
  Name:         clase6
  Namespace:    clase6
  Priority:     0
  ........
  ........
  Containers:
    hola-aws101:
  ........
  ........
      Mounts:
        /mnt/volumen/ from test-volume (ro)
        /var/run/secrets/kubernetes.io/serviceaccount from default-token-bksnv (ro)
  Volumes:
    test-volume:
      Type:       AWSElasticBlockStore (a Persistent Disk resource in AWS)
      VolumeID:   vol-0bb8ed1bd83014f5f
      FSType:     ext4
      Partition:  0
      ReadOnly:   false
  ........
  ........
  ```

  *Los volumenes solamente se pueden montar en un pod a la vez.*

- creamos el Servicio

  `kubectl apply -f https://raw.githubusercontent.com/dolguin-/aws101-kubernetes/main/clase-6/03-service.yaml`

- chequeamos que este aplicado

  `kubectl -n clase6 get svc`

  ```shell
  NAME     TYPE           CLUSTER-IP       EXTERNAL-IP                                                             PORT(S)        AGE
  clase6   LoadBalancer   10.100.157.103   <REDACTED>.us-east-1.elb.amazonaws.com   80:30109/TCP   9s
  ```

  Una vez aplicados estos cambios estamos listos para verificar que al un pod de nuestro deployment contiene el volumen montado.

### Verificamos la configuracion

Para verificar el volumen vamos a ingresar a la linea de comandos del container utilizando `kubectl exec -it <<pod_-_name>> -- bash` de esta manera podermos acceder al container que esta corriendo, de una manera similar a lo que hacemos con `Docker exec`.

- Obtenemos el nombre del **pod**

  `kubectl -n clase6 get pods`

  ```shell
  NAME                     READY   STATUS    RESTARTS   AGE
  clase6   1/1     Running   0          7m26s
  ```

- ingrasamos al pod

  `kubectl -n clase6 exec -it clase6 -- bash`

  ```shell
  root@clase6:/#
  ```

  Una ves dentro del pod imprimimos las variables de entorno ejecutando los siguientes comandos

  `cd /mnt/volumen`

  `ls`

  `df -h`

  ```shell
  root@clase6:/# cd /mnt/volumen/
  root@clase6:/mnt/volumen# ls
  ## lost+found
  root@clase6:/mnt/volumen# df -h
  Filesystem      Size  Used Avail Use% Mounted on
  overlay          80G  2.8G   78G   4% /
  tmpfs            64M     0   64M   0% /dev
  tmpfs           975M     0  975M   0% /sys/fs/cgroup
  /dev/nvme0n1p1   80G  2.8G   78G   4% /etc/hosts
  ## /dev/nvme1n1    9.8G   37M  9.7G   1% /mnt/volumen
  shm              64M     0   64M   0% /dev/shm
  tmpfs           975M   12K  975M   1% /run/secrets/kubernetes.io/serviceaccount
  tmpfs           975M     0  975M   0% /proc/acpi
  tmpfs           975M     0  975M   0% /sys/firmware
  ```

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

Para realizar las practicas no es necesario utilizar un cloud provider, la mayoria de las practicas se pueden realizar en [Play With K8s](https://labs.play-with-k8s.com/), de todas maneras para algunas practicas relacionadas con componentes que solo estan disponibles en un cloud provider es preferible que sea en un cloud provider como AWS, GCP o Azure.
El participante es 100% responsable de los costos generados para al realizar las practicas, desde este espacio renunciamos a toda responsabilidad por costos generados al realizar los laboratorios.
Les pedimos que sean concientes de remover todos los recursos utilizados cuando finalizen las practicas.

## Referencias

[1] [Documentacion de kubernetes - Volumens Persistentes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)

## Autor

Damian A. Gitto Olguin
[AWS Community Hero](https://www.youtube.com/c/damianolguinAWSHERO)
[@enlink](https://twitter.com/enlink)] / [@teracloudio](https://twitter.com/teracloudio)
<https://teracloud.io>
