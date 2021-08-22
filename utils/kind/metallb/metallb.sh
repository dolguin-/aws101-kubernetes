#!/bin/bash

#creamos el namespace para metallb
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/namespace.yaml

# creamos el secreto memberlist
kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"

# Aplicamos el manifest para desplegar metallb
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/metallb.yaml

#aguardamos a que los pods de metallb esten listos
sleep 30
# verificamos que los pods estan listos
kubectl get pods -n metallb-system

# obtenemos el pool de IPs que utilizaran los loadbalancers
# La salida del comando de docker deberia devolver un CIDR 172.19.0.0/16
# si es asi podemos utilizar el config map por defecto caso contrario hay
# que crear uno que espesifique el rango de IP que va a utilizar haciendo
# subneting para calcular el rango de ips que va a utilizar metalb.
# mas info en https://kind.sigs.k8s.io/docs/user/loadbalancer/
docker network inspect -f '{{.IPAM.Config}}' kind



## aplicamos el config map con las configuraciones por defecto
kubectl apply -f https://kind.sigs.k8s.io/examples/loadbalancer/metallb-configmap.yaml
