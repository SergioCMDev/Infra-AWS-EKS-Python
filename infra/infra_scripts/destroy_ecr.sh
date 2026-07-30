#!/bin/bash
echo "Destruyendo ECR, carpeta 3-ecr"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd $SCRIPT_DIR/.. && pwd)"
cd "$ROOT_DIR/3-ecr" || exit
#CHECK if tiene imagenes
# aws
terraform destroy --auto-approve
