#!/bin/bash
echo "Buscamos si existe el ALB de ArgoCD y lo borramos si existe"

kubectl get svc -n argocd

# Obtener el hostname del NLB desde el servicio
NLB_HOSTNAME=$(kubectl get svc argocd-server -n argocd \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)

if [[ -z $NLB_HOSTNAME ]]; then
  echo "NLB de ArgoCD no encontrado, posiblemente ya eliminado"
  exit 0
fi

echo "NLB Hostname: $NLB_HOSTNAME"

# Obtener el ARN usando el hostname
NLB_ARN=$(aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?DNSName=='$NLB_HOSTNAME'].LoadBalancerArn" \
  --output text)

if [[ -z $NLB_ARN || $NLB_ARN == "None" ]]; then
  echo "NLB ARN no encontrado en AWS, posiblemente ya eliminado"
  echo "Borrando servicio de Kubernetes..."
else
  echo "NLB ARN: $NLB_ARN"
  echo "Borrando servicio argocd-server para que el NLB Controller elimine el NLB..."
fi

kubectl delete svc argocd-server -n argocd

if [[ -n $NLB_ARN && $NLB_ARN != "None" ]]; then
  echo "Esperando a que AWS borre el NLB..."
  aws elbv2 wait load-balancers-deleted --load-balancer-arns "$NLB_ARN"
  echo "NLB de ArgoCD borrado correctamente"
fi
