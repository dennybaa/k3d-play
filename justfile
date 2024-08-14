set dotenv-load

default: k3d proxy

k3d:
    #!/bin/bash
    set -e
    if (! k3d cluster list ${K3D_CLUSTER} >& /dev/null); then
        echo -e "Creating k3d cluster...\n"
        unset KUBECONFIG
        k3d cluster create --wait --config config/k3d-config.yaml; sleep 20;
        switcher set-context k3d-${K3D_CLUSTER}

        kubectl wait -n kube-system --for=condition=Ready pod -l k8s-app=kube-dns --timeout=120s

        echo -e "Deploying core k8s services...\n"
        helm repo list | grep jetstack &>/dev/null || helm repo add jetstack https://charts.jetstack.io --force-update
        helm repo list | grep traefik &>/dev/null || helm repo add traefik https://traefik.github.io/charts --force-update

        # bootstrap phase (crds)
        helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set "crds.enabled=true" --wait
        helm install traefik traefik/traefik --namespace kube-system --wait

        # config phase
        helmfile -l name=traefik apply
        helmfile -l name=cert-manager apply
    fi

    helmfile apply
    [ $(switcher current-context) == "k3d-${K3D_CLUSTER}" ] || switcher set-context k3d-${K3D_CLUSTER} 
    kubectl get secret -n cert-manager root-secret -o jsonpath='{.data.ca\.crt}' | base64 -d > ca-cert.pem

proxy:
    scripts/redirect-proxy.sh


destroy:
    scripts/redirect-proxy.sh destroy
    k3d cluster delete $K3D_CLUSTER
