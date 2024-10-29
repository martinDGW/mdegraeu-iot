#!/bin/bash

wait_for_gitlab_ready() {
    echo "gitlab isn't ready."
    sleep 20
    
    while true; do
        PODS_NOT_READY=$(kubectl get pods -n gitlab --field-selector=status.phase!=Running -o jsonpath='{.items[*].status.containerStatuses[*].ready}' | grep -v "true" | wc -w)
        
        if [ "$PODS_NOT_READY" -eq 0 ]; then
            echo "Argocd is ready."
            break
        fi
        
        echo "Waiting for gitlab pods prep..."
        sleep 20
    done
}

kubectl create namespace gitlab

echo "127.0.0.1 gitlab.ownlab.com" | sudo tee -a /etc/hosts

helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm upgrade --install gitlab gitlab/gitlab \
    --namespace gitlab \
    --timeout 600s \
    --set global.hosts.domain=ownlab.com \
    --set global.hosts.externalIP=127.0.0.1 \
    --set certmanager-issuer.email=moi@oim.com \
    --set global.hosts.https=false

wait_for_gitlab_ready

kubectl get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode ; echo > gitlabpwd
