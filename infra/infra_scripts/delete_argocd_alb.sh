#!/bin/bash
set -euo pipefail

echo "Buscamos el LoadBalancer de ArgoCD y lo borramos si existe"

if ! kubectl get namespace argocd >/dev/null 2>&1; then
  echo "Namespace argocd no existe. Nada que borrar."
  exit 0
fi

kubectl get svc -n argocd

# Obtener el hostname del NLB desde el servicio
NLB_HOSTNAME=$(kubectl get svc argocd-server -n argocd \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)

if [[ -z "$NLB_HOSTNAME" ]]; then
  echo "NLB de ArgoCD no encontrado, posiblemente ya eliminado"
  exit 0
fi

echo "NLB Hostname: $NLB_HOSTNAME"

# Obtener el ARN usando el hostname
NLB_ARN=$(aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?DNSName=='$NLB_HOSTNAME'].LoadBalancerArn" \
  --output text)

if [[ -z "$NLB_ARN" || "$NLB_ARN" == "None" ]]; then
  echo "NLB ARN no encontrado en AWS, posiblemente ya eliminado"
  echo "Borrando servicio de Kubernetes..."
else
  echo "NLB ARN: $NLB_ARN"
  echo "Borrando servicio argocd-server para que el NLB Controller elimine el NLB..."
fi

kubectl delete svc argocd-server -n argocd --ignore-not-found

if [[ -n "$NLB_ARN" && "$NLB_ARN" != "None" ]]; then
  echo "Esperando a que AWS borre el NLB de ArgoCD (progreso visible)..."
  for i in {1..40}; do
    if aws elbv2 describe-load-balancers --load-balancer-arns "$NLB_ARN" >/dev/null 2>&1; then
      echo "[$i/40] NLB de ArgoCD sigue existiendo; AWS limpiando recursos..."
      sleep 15
    else
      echo "NLB de ArgoCD borrado correctamente"
      exit 0
    fi
  done

  echo "Timeout esperando eliminación del NLB de ArgoCD. Revisa en AWS Console."
  exit 1
fi

echo "Servicio argocd-server eliminado; no se encontró ARN en AWS para esperar más."
