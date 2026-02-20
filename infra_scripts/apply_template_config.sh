#!/bin/bash
echo "Rellenando templates, carpeta template_config"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd $SCRIPT_DIR/.. && pwd)"
cd "$ROOT_DIR/infra/4-template_config" || exit
terraform init
terraform apply --auto-approve
