#!/bin/bash

delete_line_from_hosts() {
    local PATTERN="$1"
    local HOSTS_FILE="/etc/hosts"

    sudo sed -i.bak "/$PATTERN/d" "$HOSTS_FILE"

    if [[ $? -eq 0 ]]; then
        echo "Pattern '$PATTERN' successfully removed from $HOSTS_FILE."
    else
        echo "Error: Line still exist in $HOST_FILE."
    fi
}

kubectl delete all --all -n argocd
kubectl delete all --all -n dev
kubectl delete all --all -n gitlab
kubectl delete namespace argocd dev
k3d cluster delete monpetitcluster
rm -f ./adminfile ./gitlabpwd
delete_line_from_hosts wil-app
delete_line_from_hosts gitlab
