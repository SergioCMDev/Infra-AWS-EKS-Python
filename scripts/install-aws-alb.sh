#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# echo "script dir $SCRIPT_DIR"
ROOT_DIR="$(cd $SCRIPT_DIR/.. && pwd)"
AWS_ALB_CHART_LOCAL_NAME="aws-load-balancer-controller-3.0.0.tgz"
AWS_ALB_CHART_VERSION=3.0.0
AWS_ALB_VALUES_PATH="$ROOT_DIR/charts/values/alb_values.yaml"
AWS_ALB_SERVICE_ACCOUNT_PATH="$ROOT_DIR/k8s_manifests/apps/alb_serviceAccount.yaml"
AWS_ALB_CHART_PATH="$ROOT_DIR/charts/$AWS_ALB_CHART_LOCAL_NAME"

install_alb(){
  local source=$1
  local values_file=$AWS_ALB_VALUES_PATH
  local version_flag=""

  if [[ $source != *.tgz ]]; then
    source="eks/aws-load-balancer-controller"
    version_flag="--version $AWS_ALB_CHART_VERSION"
  fi
  #COMPROBAR ERRORES
#En caso de querer que añada un serviceAccount, añadir estas lineas y quitar la 3 y 4
  # --set serviceAccount.create=false   \
  # --set controller.serviceAccount.annotations."eks\.amazonaws\.com/role-arn"="$ROLE_ARN"

  helm upgrade --install aws-load-balancer-controller $source \
  -n kube-system   \
  $version_flag \
  -f $values_file \
  --timeout 10m
}

echo "Applying ALB Service Account manifest..."
kubectl apply -f $AWS_ALB_SERVICE_ACCOUNT_PATH

sleep 3
echo "Installing ALB ..."
set +e
ERROR_MSG=$(install_alb "eks/aws-load-balancer-controller" 2>&1 | tee /dev/stderr)
EXIT_CODE=${PIPESTATUS[0]}
set -e
if [[ $EXIT_CODE -ne 0 ]]; then
  echo "Error al instalar remotamente ALB Controller $ERROR_MSG"

  if echo "$ERROR_MSG" | grep -q "EOF"; then
  echo "Encontrado EOF al descargar archivo remoto"
  echo "Instalando ALB de manera local"
  ERROR_MSG=$(install_alb "$AWS_ALB_CHART_PATH" 2>&1 | tee /dev/stderr)
  EXIT_CODE=${PIPESTATUS[0]}
    if [ $EXIT_CODE -ne 0 ]; then
      echo "Error al instalar ALB de manera local, saliendo, Error: $ERROR_MSG"
      exit 1
    fi
  else
    echo "Error al instalar ALB, saliendo"
    exit 1
  fi
fi
