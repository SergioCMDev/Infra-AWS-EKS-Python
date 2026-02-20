#!/bin/bash

INCLUDE_ECR=0
echo "Instalando infra"
./destroy_networking.sh
./destroy_eks.sh
./destroy_security.sh
if [[ $INCLUDE_ECR ]];
then
  ./destroy_ecr.sh
fi
./destroy_template_config.sh
echo "Destrucción finalizada"
