#!/bin/bash

# Script para instalar ArgoCD en EKS
set -e

echo "🚀 Iniciando instalación de ArgoCD..."

# 1. Crear namespace
echo "📦 Creando namespace argocd..."
kubectl create namespace argocd || echo "Namespace argocd ya existe"

# 2. Instalar ArgoCD
echo "⬇️  Instalando ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 3. Esperar a que los pods estén listos
echo "⏳ Esperando a que ArgoCD esté listo..."
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=argocd-server \
  -n argocd \
  --timeout=300s || echo "⚠️  Timeout esperando argocd-server"

# 4. Obtener la contraseña inicial
echo ""
echo "🔐 Contraseña inicial de ArgoCD:"
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Usuario: admin"
echo "Contraseña: $ARGOCD_PASSWORD"
echo ""

# 5. Exponer el servicio
echo "🌐 Exponiendo ArgoCD..."
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
echo "ArgoCD disponible en: https://localhost:8080"
echo ""

echo "✅ Instalación completada!"
