#!/usr/bin/env bash
# scripts/install-argocd.sh
# set -e

# export KUBECONFIG="/mnt/c/Users/sergio/.kube/config"

CHART_VERSION="9.4.2"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# echo "script dir $SCRIPT_DIR"
ROOT_DIR="$(cd $SCRIPT_DIR/../../.. && pwd)"
echo "ROOT DIR $ROOT_DIR"
CHART_LOCAL_PATH="$ROOT_DIR/charts/argo-cd-9.4.2.tgz"
VALUES_PATH="$ROOT_DIR/charts/values/argocd-values - minikube.yaml"
SECRET_REPOSITORY_PATH="$ROOT_DIR/charts/values/argocd-repository-secret.yaml"

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

bash -c "echo $KUBECONFIG"
bash -c "kubectl config current-context"

# 3. Crear namespace
echo "Creando namespace argocd..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

# 4. Instalar ArgoCD SIN password custom (se genera automáticamente)
echo "Instalando ArgoCD (puede tardar varios minutos)..."

install_argocd(){
  local source=$1
  local helm_args=()

  if [[ $source != *.tgz ]]; then
    helm_args+=(--version "$CHART_VERSION")
  fi

  helm_args+=(--set controller.serviceAccount.create=true)
  helm_args+=(-f "$VALUES_PATH")
  helm_args+=(--namespace argocd)
  helm_args+=(--timeout 10m)

  helm upgrade --install argocd "$source" "${helm_args[@]}"
}

echo "Intentando instalación remota de ArgoCD"
ERROR_OUTPUT=$(install_argocd "argo/argo-cd" 2>&1 | tee /dev/stderr) #stderror hacia stdout almacenando todo en $()
EXIT_CODE=${PIPESTATUS[0]} #Cogemos resultado del primer comando ejecutado, del installs
if [ $EXIT_CODE -ne 0 ];
  then
  echo "Error al instalar remotamente ArgoCD $ERROR_OUTPUT"
  if echo "$ERROR_OUTPUT" | grep -q "EOF"; then
    echo "Encontrado EOF al descargar archivo remoto"
    echo "Intentando instalación local de ArgoCD"
    ERROR_OUTPUT=$(install_argocd $CHART_LOCAL_PATH 2>&1  | tee /dev/stderr)
    EXIT_CODE=${PIPESTATUS[0]}
    if [ $EXIT_CODE -ne 0 ];
    then
      echo "Error al instalar localmente ArgoCD $ERROR_OUTPUT"
      echo "No se pudo instalar ArgoCD ni remotamente ni localmente"
      exit 1
    fi
  fi
fi
echo "Instalación local de ArgoCD exitosa!"

# 5. Esperar a que esté completamente listo
echo "Verificando que todos los pods estén listos..."
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=argocd-server \
  -n argocd \
  --timeout=600s

# 6. Esperar un poco más para asegurar que el secret se cree
echo "Esperando a que se genere el secret inicial..."
sleep 10


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


echo "Instalación completada!"
echo ""
echo "Próximos pasos:"
echo "   1. Accede a la UI en la URL mostrada arriba"
echo "   2. Cambia la password predeterminada"
echo "   3. Crea una aplicación con:"
echo "      kubectl apply -f k8s_manifests/platform/argocd/application.yaml"
echo ""echo "   4. ¡Disfruta de tu CD con ArgoCD!"

echo "Aplicando Manifest Secret de repositorio"
kubectl apply -f "$SECRET_REPOSITORY_PATH"

echo "Aplicando Manifest de aplicacion"
