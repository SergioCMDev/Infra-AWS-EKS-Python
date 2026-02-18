#!/bin/bash
echo "Applying Kubernetes manifests..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd $SCRIPT_DIR/.. && pwd)"

kubectl apply -f $ROOT_DIR/k8s_manifests/apps/deployment_blue.yaml
kubectl apply -f $ROOT_DIR/k8s_manifests/apps/deployment_green.yaml
kubectl apply -f $ROOT_DIR/k8s_manifests/apps/service_blue.yaml
kubectl apply -f $ROOT_DIR/k8s_manifests/apps/service_green.yaml
echo "Esperamos 20s a que se configure todo bien antes de aplicar el ingress"
sleep 20
kubectl apply -f $ROOT_DIR/k8s_manifests/apps/ingress.yaml
