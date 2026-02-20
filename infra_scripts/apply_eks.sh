#!/bin/bash
echo "Configurando EKS, carpeta eks"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd $SCRIPT_DIR/.. && pwd)"
cd "$ROOT_DIR/infra/2-eks" || exit
terraform init
terraform apply --auto-approve
