#!/bin/bash
# run on rke2 server
curl -sfL https://get.rke2.io | INSTALL_RKE2_VERSION=v1.20.4+rke2r1 sh -
systemctl daemon-reload
systemctl restart rke2-server.service 

# restart agent 
systemctl restart rke2-agent.service
