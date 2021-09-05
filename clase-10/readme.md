# External-DNS para Kubernetes

- [External-DNS para Kubernetes](#external-dns-para-kubernetes)
  - [Objetivo de la Clase](#objetivo-de-la-clase)
  - [External DNS](#external-dns)
  - [Instalación de External-DNS](#instalación-de-external-dns)
    - [IAM Policies](#iam-policies)
    - [I.R.S.A. (IAM Roles para Service Accounts)](#irsa-iam-roles-para-service-accounts)
  - [Práctica](#práctica)
    - [Preparación](#preparación)
    - [Verificamos la configuración](#verificamos-la-configuración)
  - [Remover los recursos](#remover-los-recursos)
  - [Disclaimer](#disclaimer)
  - [Autor](#autor)

## Objetivo de la Clase

Vamos a hablar un poco de la temática nativa de kubernetes con el objetivo de proveer herramientas que los ayuden a desplegar aplicaciones modernas de una manera ágil.

## External DNS

External DNS es una herramienta inspirada en el servicio cluster-internal-dns-server de kubernetes, tiene como objetivo principal herramientas para Service Discovery al exterior del cluster.

Este servicio actúa como una interfaz para interactuar con los servicios de DNS, no provee un Servidor de DNS por sí mismo.

ref: [1 - External-DNS](https://github.com/kubernetes-sigs/external-dns/blob/master/README.md)

## Instalación de External-DNS

La instalación de External-DNS depende del servicio DNS donde se encuentra delegado el dominio que vamos a utilizar por razones prácticas hoy vamos a cubrir el procedimiento de instalación para operar el DNS a través de Amazon Route53.

### IAM Policies

Para autorizar la interacción con el servicio de Route53 en nuestro nombre se deberá crear la siguiente política IAM

```json
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Action": [
       "route53:ChangeResourceRecordSets"
     ],
     "Resource": [
       "arn:aws:route53:::hostedzone/*"
     ]
   },
   {
     "Effect": "Allow",
     "Action": [
       "route53:ListHostedZones",
       "route53:ListResourceRecordSets"
     ],
     "Resource": [
       "*"
     ]
   }
 ]
}
```

- Opcional: Si lo desean pueden limitar el alcance de la política para qué External-DNS solo interactúa con las zonas que ustedes deseen solo reemplazando el `*` por el `HOSTED_ZONE_ID` en el ARN `"arn:aws:route53:::hostedzone/XXXXXXXXXX"`

### I.R.S.A. (IAM Roles para Service Accounts)

IRSA es un mecanismo por el cual se crea un IAM Role que es asignado a una Service Account de kubernetes, esto nos permite implementar el principio de privilegios mínimos , aislar credenciales y proveer los mecanismos necesarios para la auditoría vía Cloudtrails.

[Documentacion Oficial de Amazon](https://docs.aws.amazon.com/es_es/eks/latest/userguide/iam-roles-for-service-accounts.html)

EKSCTL provee una forma muy simple de implementar IRSA para proveer los accesos necesarios para External DNS, en la parte practiva demostraremos como se realiza este proceso.

## Práctica

En esta clase vamos continuar con el proyecto wordpress incluyendo todos los componentes desplegados en la clase anterior.
Todo lo realizaremos en el namespace `clase10` y los yamls para crear los siguientes componentes:

- Namespace
- PVC para mariaDB
- PVC para wordpress
- Secrets para mariaDB
- Deployment de MariaDB
- Service para MariaDB
- Deployment de Wordpress
- Service para Wordpress
- Ingress
- service account para External-DNS
- Cluster Role para External-DNS
- Cluster Role Binding para External-DNS
- Deployment para External-DNS

El objetivo de ahora en más es continuar agregando valor a este proyecto a través de las iteraciones semanales.

Como pre-requisito deberán tener instalado el **nginx-ingress controller**, clonar el repositorio del curso e ingresar a la carpeta `clase-10/`

### Preparación

- Crearemos una IAM Policy y un Role para permitirle a External-DNS interactuar con la api de AWS.

  ```shell
   aws iam create-policy --policy-name externaldns_permissions --policy-document file://iam_policy.json
   {
       "Policy": {
           "PolicyName": "externaldns_permissions",
           "PolicyId": "ANPA2D3CMCQR5WX24NR4A",
           "Arn": "arn:aws:iam::695454143523:policy/externaldns_permissions",
           "Path": "/",
           "DefaultVersionId": "v1",
           "AttachmentCount": 0,
           "PermissionsBoundaryUsageCount": 0,
           "IsAttachable": true,
           "CreateDate": "2021-09-04T15:58:36+00:00",
           "UpdateDate": "2021-09-04T15:58:36+00:00"
       }
   }
  ```

- Creamos el I.R.S.A. (IAM Role for Service Account)

  ```shell
  eksctl create iamserviceaccount \
    --name external-dns \
    --namespace clase10 \
    --cluster aws101 \
    --attach-policy-arn arn:aws:iam::695454143523:policy/externaldns_permissions \
    --approve \
    --override-existing-serviceaccounts
  # 2021-09-04 13:08:22 [ℹ]  eksctl version 0.61.0
  # 2021-09-04 13:08:22 [ℹ]  using region us-east-1
  # 2021-09-04 13:08:26 [ℹ]  1 existing iamserviceaccount(s) (kube-system/aws-node) will be excluded
  # 2021-09-04 13:08:26 [ℹ]  1 iamserviceaccount (clase10/external-dns) was included (based on the include/exclude # rules)
  # 2021-09-04 13:08:26 [!]  metadata of serviceaccounts that exist in Kubernetes will be updated, as # --override-existing-serviceaccounts was set
  # 2021-09-04 13:08:26 [ℹ]  1 task: { 2 sequential sub-tasks: { create IAM role for serviceaccount "clase10/# external-dns", create serviceaccount "clase10/external-dns" } }
  # 2021-09-04 13:08:26 [ℹ]  building iamserviceaccount stack # "eksctl-aws101-addon-iamserviceaccount-clase10-external-dns"
  # 2021-09-04 13:08:27 [ℹ]  deploying stack "eksctl-aws101-addon-iamserviceaccount-clase10-external-dns"
  # 2021-09-04 13:08:27 [ℹ]  waiting for CloudFormation stack # "eksctl-aws101-addon-iamserviceaccount-clase10-external-dns"
  # 2021-09-04 13:08:43 [ℹ]  waiting for CloudFormation stack # "eksctl-aws101-addon-iamserviceaccount-clase10-external-dns"
  # 2021-09-04 13:09:01 [ℹ]  waiting for CloudFormation stack # "eksctl-aws101-addon-iamserviceaccount-clase10-external-dns"
  # 2021-09-04 13:09:04 [ℹ]  created serviceaccount "clase10/external-dns"
  ```

- Extraemos el ARN del Role

  ```shell
  eksctl get iamserviceaccount \
    --cluster aws101 \
    -o json | jq \
      -r '.[] | select(.metadata.name=="external-dns").status.roleARN'
  # arn:aws:iam::**REDACTED**:role/eksctl-aws101-addon-iamserviceaccount-clase1-Role1-14IKSH70D3OBL
  ```

  Una vez obtenido el Role ARN vamos a editar el deployment de **External-DNS** para incluir este valor en `spec.template.metadata.annotations.iam.amazonaws.com/role`

- Aplicamos todos los manifests de la siguiente manera

  `kubectl apply -f .`

  ```shell
  cd clase-10
  kubectl apply -f .
  # namespace/clase10 created
  # persistentvolumeclaim/mariadb-data-disk created
  # persistentvolumeclaim/wp-pv-claim created
  # secret/mariadb-secrets created
  # deployment.apps/mariadb created
  # service/mariadb created
  # deployment.apps/wordpress created
  # service/wordpress created
  # ingress.networking.k8s.io/wp created
  # serviceaccount/external-dns created
  # clusterrole.rbac.authorization.k8s.io/external-dns unchanged
  # clusterrolebinding.rbac.authorization.k8s.io/external-dns unchanged
  # deployment.apps/external-dns created
  ```

### Verificamos la configuración

Una vez aplicados los cambios vamos a revisar que todas las cargas de trabajo se encuentren correctamente desplegadas como lo hicimos en la clase-9

Una vez que confirmamos que todos los objetos de la carga de trabajo están correctamente desplegados verificamos el Ingress.

- `kubectl -n clase10 get ingress`
- `kubectl -n clase10 describe ingress wp`

  ```shell
  kubectl -n clase10 get ingress
  # NAME   CLASS   HOSTS           ADDRESS                                PORTS     AGE
  # wp     nginx   wp.aws101.org   REDACTED.elb.us-east-1.amazonaws.com   80, 443   9m47s

  kubectl -n clase10 describe ingress wp
  # Name:             wp
  # Namespace:        clase10
  # Address:          abffc9ade50304ffea339b2ff57d54c2-a4f0555c32cf9ecf.elb.us-east-1.amazonaws.com
  # Default backend:  default-http-backend:80 (<error: endpoints "default-http-backend" not found>)
  # TLS:
  #   wp-tls terminates wp.aws101.org
  # Rules:
  #   Host           Path  Backends
  #   ----           ----  --------
  #   wp.aws101.org
  #                 /   wordpress:80 (192.168.53.60:80)
  # Annotations:     cert-manager.io/cluster-issuer: letsencrypt-prod
  #                 nginx.ingress.kubernetes.io/rewrite-target: /
  # Events:
  #   Type    Reason  Age                From                      Message
  #   ----    ------  ----               ----                      -------
  #   Normal  Sync    10m (x2 over 11m)  nginx-ingress-controller  Scheduled for sync
  ```

- Verificamos la configuración de External-DNS

  `kubectl -n clase10 describe deployment external-dns`
  `kubectl -n clase10 describe pod external-dns-5ff76cdc7c-dh6t2`
  `kubectl -n clase10 logs external-dns-5ff76cdc7c-dh6t2`

  ```shell
  kubectl -n clase10 describe deployment external-dns
  #   Name:               external-dns
  #   Namespace:          clase10
  #   CreationTimestamp:  Sun, 05 Sep 2021 18:41:47 -0300
  #   Labels:             app=external-dns
  #   Annotations:        deployment.kubernetes.io/revision: 1
  #   Selector:           app=external-dns
  #   Replicas:           1 desired | 1 updated | 1 total | 1 available | 0 unavailable
  #   StrategyType:       Recreate
  #   MinReadySeconds:    0
  #   Pod Template:
  #     Labels:           app=external-dns
  #     Annotations:      iam.amazonaws.com/role: arn:aws:iam::[REDACTED]:role/eksctl-aws101-addon-iamserviceaccount-clase1-Role1-14IKSH70D3OBL
  #     Service Account:  external-dns
  #     Containers:
  #     external-dns:
  #       Image:      k8s.gcr.io/external-dns/external-dns:v0.9.0
  #       Port:       <none>
  #       Host Port:  <none>
  #       Args:
  #         --source=service
  #         --source=ingress
  #         --domain-filter=aws101.org
  #         --provider=aws
  #         --aws-zone-type=public
  #         --registry=txt
  #         --txt-owner-id=my-hostedzone-identifier
  #     Limits:
  #       cpu:     100m
  #       memory:  100Mi
  #     Requests:
  #       cpu:        100m
  #       memory:     100Mi
  #     Environment:  <none>
  #     Mounts:       <none>
  #   Volumes:        <none>
  # Conditions:
  #   Type           Status  Reason
  #   ----           ------  ------
  #   Available      True    MinimumReplicasAvailable
  #   Progressing    True    NewReplicaSetAvailable
  # OldReplicaSets:  <none>
  # NewReplicaSet:   external-dns-5ff76cdc7c (1/1 replicas created)
  # Events:
  #   Type    Reason             Age   From                   Message
  #   ----    ------             ----  ----                   -------
  #   Normal  ScalingReplicaSet  13m   deployment-controller  Scaled up replica set external-dns-5ff76cdc7c to 1
  ```

Si todo está bien configurado en los logs podremos ver qué External DNS se encargó de la creación del registro DNS en la zona administrada de Route53.

  ```shell
  time="2021-09-05T21:41:50Z" level=info msg="Created Kubernetes client https://10.100.0.1:443"
  time="2021-09-05T21:41:58Z" level=info msg="Applying provider record filter for domains: [aws101.org. .aws101.org.]"
  time="2021-09-05T21:41:58Z" level=info msg="All records are already up to date"
  time="2021-09-05T21:42:59Z" level=info msg="Applying provider record filter for domains: [aws101.org. .aws101.org.]"
  time="2021-09-05T21:42:59Z" level=info msg="Desired change: CREATE wp.aws101.org A [Id: /hostedzone/**REDACTED**]"
  time="2021-09-05T21:42:59Z" level=info msg="Desired change: CREATE wp.aws101.org TXT [Id: /hostedzone/**REDACTED**]"
  time="2021-09-05T21:42:59Z" level=info msg="2 record(s) in zone aws101.org. [Id: /hostedzone/**REDACTED**] were successfully updated"
  time="2021-09-05T21:44:00Z" level=info msg="Applying provider record filter for domains: [aws101.org. .aws101.org.]"
  time="2021-09-05T21:44:00Z" level=info msg="All records are already up to date"
  ```

En este punto podremos verificar con nuestro navegador accediendo con el `fqdn` del host que definimos en nuestro ingress.

- `kubectl -n clase10 get ingress`

  ```shell
  NAME   CLASS   HOSTS           ADDRESS                                    PORTS     AGE
  wp     nginx   wp.aws101.org   **REDACTED**.elb.us-east-1.amazonaws.com   80, 443   21m
  ```

## Remover los recursos

Una vez que terminen de realizar las prácticas no se olviden de remover todos los recursos para no generar gastos no esperados.

- `kubectl delete ns clase10`
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
