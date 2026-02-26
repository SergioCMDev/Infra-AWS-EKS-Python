#!/bin/bash
echo "Destruyendo template config, carpeta 4-template_config"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd $SCRIPT_DIR/.. && pwd)"
cd "$ROOT_DIR/infra/4-template_config" || exit
terraform destroy --auto-approve
