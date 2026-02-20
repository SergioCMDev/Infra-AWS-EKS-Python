#!/bin/bash
echo "Destruyendo ecr, carpeta ecr"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd $SCRIPT_DIR/.. && pwd)"
cd "$ROOT_DIR/infra/ecr" || exit
terraform destroy --auto-approve
