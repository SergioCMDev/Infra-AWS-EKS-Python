#!/bin/bash

INCLUDE_ECR=0
echo "Instalando infra"
./apply_networking.sh
./apply_eks.sh
./apply_security.sh
if [[ $INCLUDE_ECR ]];
then
  ./apply_ecr.sh
fi
./apply_template_config.sh
echo "Instalacion finalizada"
