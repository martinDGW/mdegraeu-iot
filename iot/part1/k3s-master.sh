#!/bin/bash

set -e

sudo apt update && sudo apt install -y curl

mkdir -p ~/.kube
touch /secrets/.secrets

export INSTALL_K3S_EXEC="--write-kubeconfig-mode=644 --node-ip=198.168.56.110"

sudo curl -sfL https://get.k3s.io | sh -

sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config

token=$(sudo cat /var/lib/rancher/k3s/server/node-token)
echo $token > /secrets/.secrets
