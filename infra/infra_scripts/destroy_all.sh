#!/bin/bash
set -euo pipefail

INCLUDE_ECR="${INCLUDE_ECR:-0}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

run_step() {
  local step_name="$1"
  local script_path="$2"
  echo "========================================"
  echo "[DESTROY] Iniciando: ${step_name}"
  echo "[DESTROY] Script: ${script_path}"
  echo "========================================"
  bash "$script_path"
  echo "[DESTROY] Completado: ${step_name}"
  echo
}

echo "Iniciando destrucción de infraestructura..."
echo "INCLUDE_ECR=${INCLUDE_ECR}"
echo

echo "[DESTROY] Verificando credenciales AWS..."
# if ! aws sts get-caller-identity >/dev/null 2>&1; then
#   echo "[DESTROY] No hay credenciales AWS válidas en esta sesión."
#   echo "[DESTROY] Ejecuta login antes de destruir, por ejemplo:"
#   echo "  export AWS_PROFILE=sergio_infra_aws"
#   echo "  aws sso login"
#   exit 1
# fi
echo "[DESTROY] Credenciales AWS OK"
echo

run_step "Destroy template_config" "$SCRIPT_DIR/destroy_template_config.sh"

if [[ "$INCLUDE_ECR" -eq 1 ]]; then
  run_step "Destroy ecr" "$SCRIPT_DIR/destroy_ecr.sh"
fi

run_step "Delete app ALB ingress/lb" "$SCRIPT_DIR/delete_aws_alb.sh"
run_step "Delete ArgoCD LB service" "$SCRIPT_DIR/delete_argocd_alb.sh"
run_step "Destroy eks" "$SCRIPT_DIR/destroy_eks.sh"
run_step "Destroy networking" "$SCRIPT_DIR/destroy_networking.sh"

echo "Destrucción finalizada"
