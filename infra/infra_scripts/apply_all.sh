#!/bin/bash

INCLUDE_ECR=1
echo "Instalando infra"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash $SCRIPT_DIR/apply_networking.sh
echo -e "\n"
bash $SCRIPT_DIR/apply_eks.sh
echo -e "\n"
bash $SCRIPT_DIR/apply_security.sh
echo -e "\n"
if [[ $INCLUDE_ECR ]];
then
  bash $SCRIPT_DIR/apply_ecr.sh
  echo -e "\n"
fi
bash $SCRIPT_DIR/apply_template_config.sh
echo -e "\n"
echo "Instalacion finalizada"
