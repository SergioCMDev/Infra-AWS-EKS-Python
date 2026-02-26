#!/bin/bash
echo "Destruyendo security, carpeta 3-security"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd $SCRIPT_DIR/.. && pwd)"
cd "$ROOT_DIR/infra/3-security" || exit
terraform destroy --auto-approve
