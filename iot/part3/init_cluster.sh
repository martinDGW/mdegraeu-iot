#!/bin/bash

wait_for_argocd_ready() {
    echo "Argocd isn't ready."
    sleep 5
    
    while true; do
        # Vérifier l'état des pods
        PODS_NOT_READY=$(kubectl get pods -n argocd --field-selector=status.phase!=Running -o jsonpath='{.items[*].status.containerStatuses[*].ready}' | grep -v "true" | wc -w)
        
        if [ "$PODS_NOT_READY" -eq 0 ]; then
            echo "Argocd is ready."
            break
        fi
        
        echo "Waiting for pods prep..."
        sleep 5
    done
}

wait_for_port() {
    local PORT=$1
    local HOST="localhost"
    local TIMEOUT=${3:-60}
    local INTERVAL=5

    echo "Attente d'une réponse sur le port $PORT de $HOST..."

    local COUNTER=0

    while [[ $COUNTER -lt $TIMEOUT ]]; do
        if nc -z "$HOST" "$PORT"; then
            echo "Le port $PORT est maintenant accessible."
            return 0  # Le port est accessible
        fi
        
        echo "Waiting... ($COUNTER/$TIMEOUT secondes)"
        sleep "$INTERVAL"
        COUNTER=$((COUNTER + INTERVAL))
    done

    echo "Le port $PORT n'est toujours pas accessible après $TIMEOUT secondes."
    return 1  # Le port n'est pas accessible après le délai
}

CLUSTER_NAME="monpetitcluster"
APP_NAME="mapetiteapp"

k3d cluster create $CLUSTER_NAME
k3d kubeconfig get ${CLUSTER_NAME}
kubectl config use-context k3d-${CLUSTER_NAME}

# install argo
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

wait_for_argocd_ready

echo "forwarding port for argocd/server"
kubectl port-forward svc/argocd-server -n argocd 8080:443 &> /dev/null &

sleep 5

echo "Get the initial admin password"
ARGO_PWD=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode)
echo $ARGO_PWD > adminfile

echo "Argo login"
argocd login 127.0.0.1:8080 --username admin --password $ARGO_PWD --insecure

kubectl create namespace dev
argocd app create $APP_NAME --repo "https://github.com/martinDGW/mdegraeu-iot.git" --path app --dest-server https://kubernetes.default.svc --dest-namespace dev

argocd app set $APP_NAME --sync-policy automated --auto-prune --allow-empty --grpc-web

sleep 15

ext_ip=$(kubectl get ingress -n dev ingress -o jsonpath="{.status.loadBalancer.ingress[0].ip}")

echo "$ext_ip wil-app" | sudo tee -a /etc/hosts
