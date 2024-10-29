#!/bin/bash

set -e

sudo apt update && sudo apt install -y curl

export INSTALL_K3S_EXEC="--node-ip=198.168.56.111"

while [[ ! -f "/secrets/.secrets" ]]; do
    sleep 20
done

curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.110:6443 K3S_TOKEN=$(cat "/secrets/.secrets") sh -
