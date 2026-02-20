#!/bin/bash
echo "Configurando roles de seguridad, carpeta security"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd $SCRIPT_DIR/.. && pwd)"
cd "$ROOT_DIR/infra/3-security" || exit
terraform init
terraform apply --auto-approve
