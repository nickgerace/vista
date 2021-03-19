#!/bin/bash
# rke2 agent 

curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" sh -
systemctl enable rke2-agent.service
mkdir -p /etc/rancher/rke2/
vi /etc/rancher/rke2/config.yaml

#server: <https://IP>
#token: <cat /var/lib/rancher/rke2/server/node-token>
server:
token:

crictl config --set runtime-endpoint=unix:///run/k3s/containerd/containerd.sock
