#!/bin/bash

set -e

sudo apt update && sudo apt install -y curl
mkdir -p ~/.kube

ip="$1"
export INSTALL_K3S_EXEC="--write-kubeconfig-mode=644 --node-ip=${ip}"

echo "Installing K3S ..."
if command -v k3s >/dev/null 2>&1; then
    echo "K3s already installed"
else
    sudo curl -sfL https://get.k3s.io | sh -
    sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
fi

echo "Updating hosts file ..."
hosts=("app1.com" "app2.com" "app3.com")
for host in "${hosts[@]}"; do
    if [[ $(sudo cat /etc/hosts | grep "${host}") == "" ]]; then
        echo "${ip}    ${host}" | sudo tee -a /etc/hosts
    fi
done

echo "Deploying Kubernetes cluster ..."
paths=("/cluster/deployment" "/cluster/ingress")
for path in "${paths[@]}"; do
    for app in $(ls "${path}"); do
        kubectl apply -f "${path}/${app}"
    done
done