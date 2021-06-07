#!/bin/bash

echo "Set Europe/Rome timezone"
sudo timedatectl set-timezone Europe/Rome

echo "Add routing to the IAAS machine"
sudo ip route add 172.24.4.0/24 via 10.235.1.209
echo "Relax firewall to allow docker bridges to be reached from external networks"
sudo iptables -I DOCKER-USER -i ens3 -j ACCEPT 

docker login -u fog2021gr09 -p M]ACjbw\$7WBbPm~

echo "Creating cluster"
kind create cluster
cp ~/.kube/config ~/.kube/kind-config-eval
echo "export KUBECONFIG=/home/eval/.kube/kind-config-eval" >> .bashrc

echo "Installing metrics server"
wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
sed -i "s|- --cert-dir=/tmp|- --cert-dir=/tmp\n        - --kubelet-insecure-tls|" components.yaml
docker pull k8s.gcr.io/metrics-server/metrics-server:v0.5.0
kind load docker-image k8s.gcr.io/metrics-server/metrics-server:v0.5.0 --name kind
kubectl apply -f components.yaml
rm components.yaml

echo "Cloning repository"
git clone https://github.com/AndreFrigo/fog-cloud-computing-2021-nodejs.git
cd fog-cloud-computing-2021-nodejs

echo "Switching to production branch"
git checkout master

echo "Building and pushing production docker image"
VERSION=`cat ./app/package.json | jq -r -C .version`
echo "Working with version $VERSION"
docker build -t node-server-production .
docker tag node-server-production fog2021gr09/vehiclesapp:prod.v.$VERSION
docker push fog2021gr09/vehiclesapp:prod.v.$VERSION

echo "Switching to development branch"
git checkout develop

VERSION=`cat ./app/package.json | jq -r -C .version`
echo "Working with version $VERSION"
docker build -t node-server-develop .
docker tag node-server-develop fog2021gr09/vehiclesapp:develop.v.$VERSION
docker push fog2021gr09/vehiclesapp:develop.v.$VERSION

echo "Creating kubernetes production deployment"
kubectl create -f kubeDeployProd.yaml
echo "Creating kubernetes development deployment"
kubectl create -f kubeDeployDevelop.yaml

echo "Removing repository folder"
cd ..
rm -rf fog-cloud-computing-2021-nodejs

echo "Adding master ip to .bashrc"
MASTER_IP=`docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' kind-control-plane`
echo "export MASTER_IP=$MASTER_IP" >> .bashrc
