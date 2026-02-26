#!/bin/bash
echo "Applying Kubernetes manifests..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd $SCRIPT_DIR/.. && pwd)"
K8S_MANIFESTS_DIR="$ROOT_DIR/k8s/manifests"

kubectl apply -k $K8S_MANIFESTS_DIR/overlays/eks/
