#!/bin/bash
echo "Configurando networking, carpeta networking"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd $SCRIPT_DIR/.. && pwd)"
cd "$ROOT_DIR/infra/1-networking" || exit
terraform init
terraform apply --auto-approve
