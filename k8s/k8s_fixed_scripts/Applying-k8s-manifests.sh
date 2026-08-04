#!/bin/bash
set -euo pipefail

echo "Applying Kubernetes manifests..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd $SCRIPT_DIR/.. && pwd)"
K8S_MANIFESTS_DIR="$ROOT_DIR/manifests"
ALB_INGRESS_FILE="$ROOT_DIR/../infra/4-template_config/rendered/k8s/ingress.yaml"

kubectl apply -k $K8S_MANIFESTS_DIR/overlays/eks/

if [[ -f "$ALB_INGRESS_FILE" ]]; then
	echo "Applying rendered ALB ingress manifest..."
	kubectl apply -f "$ALB_INGRESS_FILE"
else
	echo "Rendered ALB ingress not found at $ALB_INGRESS_FILE"
	echo "Run infra/infra_scripts/apply_template_config.sh to regenerate it."
	exit 1
fi
