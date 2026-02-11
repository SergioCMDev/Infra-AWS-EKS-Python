#!/usr/bin/env bash
# scripts/install-argocd.sh
set -e
ROLE_ARN=$1
if [ -z "$ROLE_ARN" ]; then
  echo "Error: Debes proporcionar el ARN del rol de ArgoCD"
  echo "Uso: ./install-argocd.sh <ROLE_ARN>"
  exit 1
fi

echo "Instalando ArgoCD con Helm..."
# 0. Verificar si hay instalación previa y limpiar
if kubectl get namespace argocd &> /dev/null || kubectl get crd applications.argoproj.io &> /dev/null 2>&1; then
  echo "Detectada instalación previa de ArgoCD"
  echo "Ejecutando limpieza..."

  bash "$(dirname "$0")/cleanup-argocd.sh"

  echo "Esperando 10 segundos para que K8s termine de limpiar..."
  sleep 10
fi

# 1. Instalar Helm si no está instalado
if ! command -v helm &> /dev/null; then
  echo "Instalando Helm..."
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# 2. Agregar repo de ArgoCD
echo "Agregando repositorio de Helm..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# 3. Crear namespace
echo "Creando namespace argocd..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# 4. Instalar ArgoCD SIN password custom (se genera automáticamente)
echo "Instalando ArgoCD (puede tardar varios minutos)..."

helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --set server.service.type=LoadBalancer \
  --set server.service.annotations."service\.beta\.kubernetes\.io/aws-load-balancer-scheme"=internet-facing \
  --set controller.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="$ROLE_ARN" \
  --set server.replicas=2 \
  --set controller.replicas=1 \
  --set repoServer.replicas=1 \
  --set applicationSet.replicas=1 \
  --set notifications.enabled=false \
  --set dex.enabled=false \
  --set redis.enabled=true \
  --timeout 10m

# 5. Esperar a que esté completamente listo
echo "Verificando que todos los pods estén listos..."
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=argocd-server \
  -n argocd \
  --timeout=600s

# 6. Esperar un poco más para asegurar que el secret se cree
echo "Esperando a que se genere el secret inicial..."
sleep 10

# 7. Obtener URL del LoadBalancer
echo "Esperando asignación de LoadBalancer..."
sleep 30

ARGOCD_URL=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

if [ -z "$ARGOCD_URL" ]; then
  ARGOCD_URL=$(kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
fi

# 8. Obtener password generada automáticamente
echo "Obteniendo credenciales generadas automáticamente..."

# Esperar hasta que el secret exista
for i in {1..10}; do
  ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d)
  if [ -n "$ARGOCD_PASSWORD" ]; then
    break
  fi
  echo "Esperando creación del secret... (intento $i/10)"
  sleep 5
done

if [ -z "$ARGOCD_PASSWORD" ]; then
  echo " No se pudo obtener la password automática"
  echo "   Ejecuta manualmente:"
  echo "   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
  ARGOCD_PASSWORD="[Ver comando arriba]"
fi

# 9. Mostrar credenciales
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "ArgoCD instalado correctamente!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Credenciales de acceso:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -n "$ARGOCD_URL" ]; then
  echo "URL:      https://${ARGOCD_URL}"
else
  echo "URL:      Esperando asignación..."
  echo "          Ejecuta: kubectl get svc argocd-server -n argocd"
fi

echo "Usuario:  admin"
echo "Password: ${ARGOCD_PASSWORD}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo " IMPORTANTE:"
echo "   1. ¡GUARDA ESTA PASSWORD EN UN LUGAR SEGURO!"
echo "   2. Cámbiala después del primer login"
echo "   3. Ve a User Info → Update Password en la UI"
echo ""

# 10. Mostrar estado
echo "Estado de los pods de ArgoCD:"
kubectl get pods -n argocd
echo ""

echo "Información del LoadBalancer:"
kubectl get svc argocd-server -n argocd
echo ""

echo "Instalación completada!"
echo ""
echo "Próximos pasos:"
echo "   1. Accede a la UI en la URL mostrada arriba"
echo "   2. Cambia la password predeterminada"
echo "   3. Crea una aplicación con:"
echo "      kubectl apply -f k8s_manifests/platform/argocd/application.yaml"
echo ""echo "   4. ¡Disfruta de tu CD con ArgoCD!"
