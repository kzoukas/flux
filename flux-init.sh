#!/usr/bin/env bash

# https://github.com/stefanprodan/gitops-istio/blob/master/scripts/flux-init.sh

set -e

if [[ ! -x "$(command -v kubectl)" ]]; then
    echo "kubectl not found"
    exit 1
fi

if [[ ! -x "$(command -v helm)" ]]; then
    echo "helm not found"
    exit 1
fi

helm repo add fluxcd https://charts.fluxcd.io

echo ">>> Installing Flux"
kubectl create ns flux-system || true
helm upgrade -i flux fluxcd/flux \
--wait \
--values flux-values.yaml \
--namespace flux-system

echo ">>> Installing Helm Operator"
## For setting up reposiotories, check the helm chart values  for configureRepositories
## https://github.com/fluxcd/helm-operator/blob/master/chart/helm-operator/values.yaml#L65
## Article for configureRepositories written here: 
## https://gaunacode.com/configuring-flux-to-use-helm-charts-from-azure-container-registry

kubectl apply -f https://raw.githubusercontent.com/fluxcd/helm-operator/1.1.0/deploy/crds.yaml
helm upgrade -i helm-operator fluxcd/helm-operator \
--wait \
--set git.ssh.secretName=flux-git-deploy \
--set helm.versions=v3 \
--namespace flux-system
# --set configureRepositories.enable=true \
# --set configureRepositories.repositories[0].name=$(ACR.Name),configureRepositories.repositories[0].url=$(ACR.Url),configureRepositories.repositories[0].username=$(KubernetesServicePrincipal.ClientId),configureRepositories.repositories[0].password=$(KubernetesServicePrincipal.ClientSecret) \

echo ">>> GitHub deploy key"
kubectl -n flux-system logs deployment/flux | grep identity.pub | cut -d '"' -f2

# wait until flux is able to sync with repo
echo ">>> Waiting on user to add above deploy key to Github with write access"
until kubectl logs -n flux-system deployment/flux | grep event=refreshed
do
  sleep 5
done
echo ">>> Github deploy key is ready"

echo ">>> Cluster bootstrap done!"