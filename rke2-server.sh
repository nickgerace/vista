#!/bin/bash
# rke2 server 

mkdir -p /var/lib/rancher/rke2/server/manifests/
curl https://raw.githubusercontent.com/nickgerace/vista/main/kube-flannel.yml -o /var/lib/rancher/rke2/server/manifests/kube-flannel.yml

mkdir -p /etc/rancher/rke2
touch /etc/rancher/rke2/config.yaml
echo 'disable: "rke2-canal"' > /etc/rancher/rke2/config.yaml

curl -sfL https://get.rke2.io | sh - 

systemctl enable rke2-server.service
systemctl start rke2-server.service

sleep 15
cat /var/lib/rancher/rke2/server/node-token

export PATH=$PATH:/var/lib/rancher/rke2/bin/
export KUBECONFIG="/etc/rancher/rke2/rke2.yaml"
