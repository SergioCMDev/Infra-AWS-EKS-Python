#!/bin/bash
echo "Applying Kubernetes manifests for minikube..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd $SCRIPT_DIR/.. && pwd)"
K8S_MANIFESTS_DIR="$ROOT_DIR/manifests"
# echo "DIR $K8S_MANIFESTS_DIR"

kubectl apply -k $K8S_MANIFESTS_DIR/overlays/minikube/
kubectl apply -f $K8S_MANIFESTS_DIR/base/ingress-green.yaml
kubectl apply -f $K8S_MANIFESTS_DIR/base/ingress-blue.yaml
