#!/bin/bash
echo "Applying Kubernetes manifests..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd $SCRIPT_DIR/.. && pwd)"
K8S_MANIFEST_DIR="$ROOT_DIR/rendered/k8s"
K8S_FIXED_MANIFEST_DIR="$ROOT_DIR/k8s_fixed_manifests"

kubectl apply -f $K8S_MANIFEST_DIR/deployment_blue.yaml
kubectl apply -f $K8S_MANIFEST_DIR/deployment_green.yaml
kubectl apply -f $K8S_FIXED_MANIFEST_DIR/service_blue.yaml
kubectl apply -f $K8S_FIXED_MANIFEST_DIR/service_green.yaml

kubectl apply -f $K8S_MANIFEST_DIR/ingress.yaml
