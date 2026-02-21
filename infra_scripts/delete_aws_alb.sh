#!/bin/bash
echo "Buscamos si existe AWS ALB y lo borramos si existe"

ALB_NAME=$(kubectl get ingress main-ingress -n default   -o jsonpath='{.metadata.annotations.alb\.ingress\.kubernetes\.io/load-balancer-name}')
echo "$ALB_NAME"
if [[ -z $ALB_NAME ]]; then
  echo "ALB NAME no encontrado, posiblemente ya eliminado"
  exit 1
fi
ALB_ARN=$(aws elbv2 describe-load-balancers --names "$ALB_NAME" --query 'LoadBalancers[0].LoadBalancerArn' --output text)
echo "$ALB_ARN"
if [[ -z $ALB_ARN ]]; then
  echo "ALB ARN no encontrado, posiblemente ya eliminado"
  exit 0
fi
kubectl delete ingress main-ingress -n default
echo "Borrado AWS ALB"
