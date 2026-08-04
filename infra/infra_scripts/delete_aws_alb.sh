#!/bin/bash
set -euo pipefail

echo "Buscamos y borramos el ALB de la app (ingress main-ingress en namespace default)."
echo "Nota: este script NO borra el LoadBalancer de ArgoCD (service argocd-server en namespace argocd)."

wait_ingress_deleted() {
  echo "Esperando a que desaparezca el recurso ingress/main-ingress..."
  for i in {1..40}; do
    if kubectl get ingress main-ingress -n default >/dev/null 2>&1; then
      deletion_ts=$(kubectl get ingress main-ingress -n default -o jsonpath='{.metadata.deletionTimestamp}' 2>/dev/null || true)
      if [[ -n "$deletion_ts" ]]; then
        echo "[$i/40] ingress en Terminating (finalizer ALB en limpieza)."
      else
        echo "[$i/40] ingress sigue presente; esperando reconciliación de borrado..."
      fi
      sleep 15
    else
      echo "ingress/main-ingress eliminado de Kubernetes."
      return 0
    fi
  done

  echo "Timeout esperando eliminación de ingress/main-ingress."
  return 1
}

ALB_NAME=""
if kubectl get ingress main-ingress -n default >/dev/null 2>&1; then
  ALB_NAME=$(kubectl get ingress main-ingress -n default -o jsonpath='{.metadata.annotations.alb\.ingress\.kubernetes\.io/load-balancer-name}')
fi

if [[ -z "$ALB_NAME" ]]; then
  echo "No existe main-ingress o no tiene load-balancer-name. Posiblemente ya eliminado."
  exit 0
fi

echo "ALB detectado: $ALB_NAME"
ALB_ARN=$(aws elbv2 describe-load-balancers --names "$ALB_NAME" --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null || true)

if [[ -z "$ALB_ARN" || "$ALB_ARN" == "None" ]]; then
  echo "ALB ARN no encontrado en AWS; el ALB ya fue eliminado (o está fuera de inventario por borrado en curso)."
  # Intentamos borrar el ingress por limpieza si sigue presente.
  kubectl delete ingress main-ingress -n default --ignore-not-found
  wait_ingress_deleted
  echo "No es necesario esperar más por ALB: AWS ya no devuelve ese ALB por nombre."
  exit 0
fi

echo "ALB ARN: $ALB_ARN"
kubectl delete ingress main-ingress -n default --ignore-not-found
echo "Ingress main-ingress eliminado. Esperando borrado del ALB en AWS..."

echo "Usando sondeo por nombre para mostrar progreso en tiempo real..."

for i in {1..40}; do
  if aws elbv2 describe-load-balancers --names "$ALB_NAME" >/dev/null 2>&1; then
    echo "[$i/40] ALB sigue existiendo; AWS aún está limpiando recursos..."
    sleep 15
  else
    echo "ALB $ALB_NAME eliminado correctamente en AWS."
    wait_ingress_deleted
    exit 0
  fi
done

echo "Timeout esperando eliminación del ALB. Revisa en AWS Console si sigue en proceso de borrado."
exit 1
