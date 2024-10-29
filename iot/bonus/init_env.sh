#!/bin/bash
read -p "Remove installed docker kubectl ? " remove
if [[ $remove == [Yy] ]]; then
    echo "Removing docker ..."

    sudo apt remove --purge docker-ce docker-ce-cli containerd.io
    sudo rm -rf /var/lib/docker /etc/docker

    echo "Removing kubectl ..."

    kubeadm reset
    sudo apt purge kubeadm kubectl kubelet kubernetes-cni kube*   
    sudo rm -rf ~/.kube

fi

read -p "Install docker kubectl ? " confirm
if [[ $confirm == [Yy] ]]; then

    echo " Installing docker"
    if ! command -v docker >/dev/null 2>&1; then

        # Add Docker's official GPG key:
        for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
        sudo apt update
        sudo apt install ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

        # Add the repository to Apt sources:
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
          $(. /etc/os-release && echo "bookworm") stable" | \
          sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt update

        sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        sudo usermod -aG docker $USER
        sudo systemctl restart docker

    else
        echo "Docker already installed"
    fi
    # ####################### #
    echo "Installing kubectl"
    if ! command -v kubectl >/dev/null 2>&1; then

        sudo apt update
        sudo apt install -y apt-transport-https ca-certificates curl gnupg
        curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
        sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
        echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
        sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list
        sudo apt update
        sudo apt install -y kubectl

        kubectl version --client

    else
        echo "Kubectl already installed"
    fi
    # ####################### #
    echo "Installing K3D ..."
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

    if ! command -v argocd >/dev/null 2>&1; then
        curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
        sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
        rm argocd-linux-amd64
    fi

    if ! command -v helm >/dev/null 2>&1; then
        snap install helm --classic
    fi
fi
