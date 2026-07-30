#!/bin/bash
echo "Configurando ECR, carpeta 3-ecr"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd $SCRIPT_DIR/.. && pwd)"
cd "$ROOT_DIR/3-ecr" || exit
terraform init
terraform apply --auto-approve
