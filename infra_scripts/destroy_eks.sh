#!/bin/bash
echo "Destruyendo EKS, carpeta 2-eks"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd $SCRIPT_DIR/.. && pwd)"
cd "$ROOT_DIR/infra/2-eks" || exit
terraform destroy --auto-approve
