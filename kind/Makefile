install:
	echo "Setting up kind"
	kind create cluster --name aws101 \
		--config kind-cluster.yml
lb:
	echo "Setting up kind"
	metallb/metallb.sh
delete:
	echo "Removing kind Cluster"
	kind delete cluster --name aws101
all: install lb
