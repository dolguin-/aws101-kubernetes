# Volúmenes

- [Volúmenes](#volúmenes)
  - [Definición](#definición)
  - [Tipos](#tipos)
    - [awsElasticBlockStore](#awselasticblockstore)
  - [Práctica](#práctica)
    - [Preparación](#preparación)
    - [Ejemplo awsElasticBlockStore](#ejemplo-awselasticblockstore)
    - [Verificamos la configuración](#verificamos-la-configuración)
  - [Remover los recursos](#remover-los-recursos)
  - [Disclaimer](#disclaimer)
  - [Referencias](#referencias)
  - [Autor](#autor)

## Definición

Los volúmenes en Kubernetes proporcionan una solución para aplicaciones que requieren conservar el estado en disco provisionando una capa de abstracción para la gestión de volúmenes.

Normalmente el almacenamiento en containers es efímero y cuando el container es reemplazado por un fallo o un despliegue por Kubelet se limpia el estado. Otro problema común también, es compartir archivos entre container corriendo en un Pod. Estos problemas son solucionados con **Kubernetes Volumes**.

En Kubernetes soporta distintos tipos de volúmenes. Un pod puede usar múltiples volúmenes simultáneamente. Los tipos de volúmenes efímeros solamente serán persistentes durante el ciclo de vida del pod mientras que los volúmenes persistentes continuarán existiendo más allá del tiempo de vida de un Pod. Cuando un Pod es detenido Kubernetes destruye los volúmenes efímeros, pero no lo hace con los volúmenes persistentes. Cabe aclarar que cualquiera sea el tiempo de volumen los datos son mantenidos cuando un container se reinicia.

Para utilizar un Volumen se debe declarar `.spec.volumes` y también donde el volumen va a ser montado `.spec.containers[*].volumeMounts` en la especificación del container. De esta forma el container podrá ver el sistema de archivos tanto de su Container Image como de los volúmenes asociados. El root filesystem corresponde a la imagen del container mientras que los volúmenes son montados en las rutas especificadas en `volumeMounts`, es importante aclarar que **no se pueden montar volúmenes dentro de otros volúmenes o hacer hard links entre volúmenes distintos** y también que cada container incluido en el pod debe especificar donde montar cada volumen.
Ref: [1- Documentacion oficial](#Referencias)

## Tipos

Kubernetes tiene múltiples tipos de volúmenes que se pueden asociar a las cargas de trabajo, ConfigMaps ya fue cubierta en la Clase-5 y por cuestiones de tiempo en este curso vamos cubrir algunas de ellas (persistentVolumeClaim, awsElasticBlockStore).

1. awsElasticBlockStore
1. azureDisk
1. azureFile
1. cephfs
1. cinder
1. configMap
1. downwardAPI
1. emptyDir
1. fc (fibre channel)
1. gcePersistentDisk
1. glusterfs
1. hostPath
1. iscsi
1. local
1. nfs
1. persistentVolumeClaim
1. portworxVolume
1. projected
1. projected
1. rbd
1. secret
1. vsphereVolume

### awsElasticBlockStore

Este tipo de volumen de kubernetes utiliza el CCM para interactuar con la api de aws montar un volumen Amazon EBS en nuestro Pod. El Volumen EBS será persistente por lo que al eliminar el Pod este mantendrá el contenido.

- Como ventaja podemos pre-cargar contenido en el volumen que luego utilizaremos en nuestros pods.
- Como desventaja los volúmenes tienen que estar pre-creados para poder utilizarlos.

hay algunas restricciones para poder utilizar `awsElasticBlockStore`:

- Los Pods deben correr sobre instancias EC2.
- La instancia deberá estar en la misma Az que el volumen EBS.
- EBS solo soporta ser montado en una instancia, por lo que para cada Pod deberemos provisionar un volumen.

Ejemplo:

 ```yaml
 apiVersion: v1
 kind: Pod
 metadata:
   name: test-ebs
 spec:
   containers:
   - image: k8s.gcr.io/test-webserver
     name: test-container
     volumeMounts:
     - mountPath: /test-ebs
       name: test-volume
   volumes:
   - name: test-volume
     # This AWS EBS volume must already exist.
     awsElasticBlockStore:
       volumeID: "<volume id>"
       fsType: ext4
 ```

## Práctica

Para esta clase por cuestión de tiempo solo vamos probar **awsElasticBlockStore**, para ello vamos a crear el namespace `clase6` luego vamos a crear un Pod `test-ebs` donde crearemos el volumen y lo expondremos a través de un `service` llamado `clase6`.

### Preparación

 Lo primero que vamos a hacer para este práctico es crear el namespace

- Aplicamos el manifest que crea nuestro namespace

 `kubectl apply -f https://raw.githubusercontent.com/dolguin-/aws101-kubernetes/main/clase-6/00-namespace.yaml`

Una vez que tenemos nuestro namespace preparado pasamos a probar las distintas formas de crear volúmenes en k8s

### Ejemplo awsElasticBlockStore

- Creamos el volumen utilizando el CLI

 `aws ec2 create-volume --availability-zone=us-east-1a --size=10 --volume-type=gp3`
 Debes estar seguro que la availability zone sea la misma de la instancia que trabaja como worker node.

 ```shell
 {
   "AvailabilityZone": "us-east-1f",
   "CreateTime": "2021-08-12T11:28:09+00:00",
   "Encrypted": false,
   "Size": 10,
   "SnapshotId": "",
   "State": "creating",
   "VolumeId": "vol-0c6cf1e29447273d6",
   "Iops": 3000,
   "Tags": [],
   "VolumeType": "gp3",
   "MultiAttachEnabled": false,
   "Throughput": 125
 }
 ```

- Aplicamos el manifest que despliega nuestro pod

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

### Verificamos la configuración

Para verificar el volumen vamos a ingresar a la línea de comandos del container utilizando `kubectl exec -it <<pod_-_name>> -- bash` de esta manera podremos acceder al contenedor que está corriendo, de una manera similar a lo que hacemos con `Docker exec`.

- Obtenemos el nombre del **pod**

 `kubectl -n clase6 get pods`

 ```shell
 NAME                     READY   STATUS    RESTARTS   AGE
 clase6   1/1     Running   0          7m26s
 ```

- ingresamos al pod

 `kubectl -n clase6 exec -it clase6 -- bash`

 ```shell
 root@clase6:/#
 ```

 Una vez dentro del pod imprimimos las variables de entorno ejecutando los siguientes comandos

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

`kubectl delete ns clase6`
`aws ec2 delete-volume --volume-id vol-0c6cf1e29447273d6`

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

[1] [Documentacion de kubernetes - Volume](https://kubernetes.io/docs/concepts/storage/volumes/)

## Autor

Damian A. Gitto Olguin
[AWS Community Hero](https://www.youtube.com/c/damianolguinAWSHERO)
[@enlink](https://twitter.com/enlink)] / [@teracloudio](https://twitter.com/teracloudio)
<https://teracloud.io>
