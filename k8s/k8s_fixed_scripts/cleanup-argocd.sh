#!/usr/bin/env bash
# scripts/cleanup-argocd.sh
set -e

echo "Limpiando instalación anterior de ArgoCD..."

# 1. Eliminar namespace (esto borra la mayoría de recursos)
if kubectl get namespace argocd &> /dev/null; then
  echo "Eliminando namespace argocd..."
  kubectl delete namespace argocd --ignore-not-found

  # Esperar a que se elimine completamente
  echo "Esperando a que se elimine el namespace..."
  while kubectl get namespace argocd &> /dev/null 2>&1; do
    sleep 2
  done
  echo "Namespace eliminado"
fi

# 2. Eliminar CRDs (Custom Resource Definitions)
echo "Eliminando CRDs de ArgoCD..."
kubectl delete crd applications.argoproj.io --ignore-not-found
kubectl delete crd applicationsets.argoproj.io --ignore-not-found
kubectl delete crd appprojects.argoproj.io --ignore-not-found

# 3. Eliminar ClusterRoles
echo "Eliminando ClusterRoles..."
kubectl delete clusterrole argocd-application-controller --ignore-not-found
kubectl delete clusterrole argocd-server --ignore-not-found
kubectl delete clusterrole argocd-redis-ha --ignore-not-found

# 4. Eliminar ClusterRoleBindings
echo "Eliminando ClusterRoleBindings..."
kubectl delete clusterrolebinding argocd-application-controller --ignore-not-found
kubectl delete clusterrolebinding argocd-server --ignore-not-found
kubectl delete clusterrolebinding argocd-redis-ha --ignore-not-found

# 5. Verificar que todo se eliminó
echo ""
echo "Verificando limpieza..."
if kubectl get crd | grep -q argoproj; then
  echo "Aún quedan CRDs de ArgoCD:"
  kubectl get crd | grep argoproj
  echo "Eliminándolos..."
  kubectl get crd | grep argoproj | awk '{print $1}' | xargs kubectl delete crd --ignore-not-found
fi

if kubectl get clusterrole | grep -q argocd; then
  echo "Aún quedan ClusterRoles de ArgoCD:"
  kubectl get clusterrole | grep argocd
  echo "Eliminándolos..."
  kubectl get clusterrole | grep argocd | awk '{print $1}' | xargs kubectl delete clusterrole --ignore-not-found
fi

if kubectl get clusterrolebinding | grep -q argocd; then
  echo "Aún quedan ClusterRoleBindings de ArgoCD:"
  kubectl get clusterrolebinding | grep argocd
  echo "Eliminándolos..."
  kubectl get clusterrolebinding | grep argocd | awk '{print $1}' | xargs kubectl delete clusterrolebinding --ignore-not-found
fi

echo ""
echo "Limpieza completada!"
echo "   Puedes proceder con la instalación de ArgoCD"
