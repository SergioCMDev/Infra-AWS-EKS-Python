#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OBS_APPS_DIR="$ROOT_DIR/observability/applications"
OBS_CONFIGMAPS_DIR="$ROOT_DIR/observability/configMaps"

preflight_ebs_storage() {
  echo "Preflight: validando EBS CSI Driver y StorageClass gp3..."

  if ! kubectl get csidriver ebs.csi.aws.com >/dev/null 2>&1; then
    echo "Falta el CSI driver ebs.csi.aws.com en el cluster."
    echo "Instalalo antes de continuar (ejemplo):"
    echo "  aws eks create-addon --cluster-name mi-cluster --addon-name aws-ebs-csi-driver --resolve-conflicts OVERWRITE"
    exit 1
  fi

  if ! kubectl get storageclass gp3 >/dev/null 2>&1; then
    echo "No existe StorageClass gp3. Creandola automaticamente..."
    kubectl apply -f - <<'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
parameters:
  type: gp3
EOF
  fi
}

wait_argocd_app_ready() {
  local app_name="$1"
  local timeout_seconds="$2"
  local require_healthy="${3:-true}"
  local allow_synced_degraded="${4:-false}"
  local allow_synced_progressing="${5:-false}"
  local elapsed=0
  local step=10

  echo "Esperando reconciliacion de ${app_name}..."
  while (( elapsed < timeout_seconds )); do
    local sync_status
    local health_status
    local operation_phase

    sync_status=$(kubectl get application "$app_name" -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null || true)
    health_status=$(kubectl get application "$app_name" -n argocd -o jsonpath='{.status.health.status}' 2>/dev/null || true)
    operation_phase=$(kubectl get application "$app_name" -n argocd -o jsonpath='{.status.operationState.phase}' 2>/dev/null || true)

    if [[ "$operation_phase" == "Failed" ]]; then
      echo "Sync fallido para ${app_name}. Detalle de operacion:"
      kubectl get application "$app_name" -n argocd -o jsonpath='{.status.operationState.message}{"\n"}' || true

      echo "Recursos con error en el sync result:"
      kubectl get application "$app_name" -n argocd -o jsonpath='{range .status.operationState.syncResult.resources[*]}{.kind}{" "}{.namespace}{"/"}{.name}{" status="}{.status}{" msg="}{.message}{"\n"}{end}' || true

      echo "Resources Degraded/OutOfSync reportados por ArgoCD:"
      kubectl get application "$app_name" -n argocd -o jsonpath='{range .status.resources[*]}{.kind}{" "}{.namespace}{"/"}{.name}{" health="}{.health.status}{" sync="}{.status}{"\n"}{end}' | grep -E "health=Degraded|sync=OutOfSync" || true
      return 1
    fi

    if [[ "$sync_status" == "Synced" && ( "$require_healthy" == "false" || "$health_status" == "Healthy" ) ]]; then
      echo "${app_name} listo: sync=${sync_status} health=${health_status}"
      return 0
    fi

    if [[ "$allow_synced_degraded" == "true" && "$sync_status" == "Synced" && "$health_status" == "Degraded" && ( -z "$operation_phase" || "$operation_phase" == "Succeeded" ) ]]; then
      echo "${app_name} en Synced+Degraded sin operación fallida. Continuamos con advertencia."
      kubectl get application "$app_name" -n argocd -o jsonpath='{range .status.resources[*]}{.kind}{" "}{.namespace}{"/"}{.name}{" health="}{.health.status}{" sync="}{.status}{"\n"}{end}' | grep "health=Degraded" || true
      return 0
    fi

    if [[ "$allow_synced_progressing" == "true" && "$sync_status" == "Synced" && "$health_status" == "Progressing" && ( -z "$operation_phase" || "$operation_phase" == "Succeeded" ) ]]; then
      echo "${app_name} en Synced+Progressing sin operación fallida. Continuamos y validamos en comprobaciones finales."
      return 0
    fi

    echo "${app_name}: sync=${sync_status:-<vacío>} health=${health_status:-<vacío>} op=${operation_phase:-<vacío>} (${elapsed}s/${timeout_seconds}s)"

    if (( elapsed > 0 && elapsed % 60 == 0 )); then
      echo "Diagnostico rapido de ${app_name} (conditions):"
      kubectl get application "$app_name" -n argocd -o jsonpath='{range .status.conditions[*]}- {.type}: {.message}{"\n"}{end}' || true
    fi

    sleep "$step"
    elapsed=$((elapsed + step))
  done

  echo "Timeout esperando ${app_name}. Estado actual:"
  kubectl get application "$app_name" -n argocd -o yaml || true
  return 1
}

wait_observability_crds_established() {
  local crds=(
    "alertmanagers.monitoring.coreos.com"
    "podmonitors.monitoring.coreos.com"
    "probes.monitoring.coreos.com"
    "prometheuses.monitoring.coreos.com"
    "prometheusrules.monitoring.coreos.com"
    "servicemonitors.monitoring.coreos.com"
    "thanosrulers.monitoring.coreos.com"
  )

  echo "Validando CRDs de Prometheus Operator en estado Established..."
  for crd in "${crds[@]}"; do
    if kubectl get crd "$crd" >/dev/null 2>&1; then
      kubectl wait --for=condition=Established "crd/$crd" --timeout=180s
    else
      echo "Aviso: no se encontro $crd (puede variar por version de chart)."
    fi
  done
}

cleanup_crd_last_applied_annotation() {
  local crds=(
    "alertmanagerconfigs.monitoring.coreos.com"
    "alertmanagers.monitoring.coreos.com"
    "podmonitors.monitoring.coreos.com"
    "probes.monitoring.coreos.com"
    "prometheusagents.monitoring.coreos.com"
    "prometheuses.monitoring.coreos.com"
    "prometheusrules.monitoring.coreos.com"
    "scrapeconfigs.monitoring.coreos.com"
    "servicemonitors.monitoring.coreos.com"
    "thanosrulers.monitoring.coreos.com"
  )

  echo "Limpiando anotacion kubectl.kubernetes.io/last-applied-configuration en CRDs existentes..."
  for crd in "${crds[@]}"; do
    if kubectl get crd "$crd" >/dev/null 2>&1; then
      kubectl annotate crd "$crd" kubectl.kubernetes.io/last-applied-configuration- >/dev/null 2>&1 || true
    fi
  done
}

apply_app_manifest() {
  local app_file="$1"
  local app_name="$2"

  if [[ ! -f "$app_file" ]]; then
    echo "No existe manifest: $app_file"
    exit 1
  fi

  echo "Aplicando ${app_name} desde $(basename "$app_file")"
  kubectl apply -f "$app_file"
  kubectl wait --for=jsonpath='{.metadata.name}'="$app_name" application/"$app_name" -n argocd --timeout=120s

  # Limpia operaciones encoladas previas para evitar reintentos con estrategia antigua.
  kubectl patch application "$app_name" -n argocd --type merge -p '{"operation":null}' >/dev/null 2>&1 || true

  # Fuerza refresh, pero deja que Argo use la estrategia de sync declarada en la app.
  kubectl annotate application "$app_name" -n argocd argocd.argoproj.io/refresh=hard --overwrite >/dev/null 2>&1 || true
}

echo "Verificando namespace argocd"
kubectl get namespace argocd >/dev/null

preflight_ebs_storage

echo "1) CRDs de observabilidad"
cleanup_crd_last_applied_annotation
apply_app_manifest "$OBS_APPS_DIR/app-observability-crds-eks.yaml" "app-observability-crds-eks"
wait_argocd_app_ready "app-observability-crds-eks" 900 false
wait_observability_crds_established

echo "2) Stack base kube-prometheus-stack"
apply_app_manifest "$OBS_APPS_DIR/app-observability-eks.yaml" "app-observability-eks"
wait_argocd_app_ready "app-observability-eks" 1200 true true

echo "3) Tempo"
apply_app_manifest "$OBS_APPS_DIR/app-observability-tempo-eks.yaml" "app-observability-tempo-eks"
wait_argocd_app_ready "app-observability-tempo-eks" 900 true false true

echo "4) Loki"
apply_app_manifest "$OBS_APPS_DIR/app-observability-loki-eks.yaml" "app-observability-loki-eks"
wait_argocd_app_ready "app-observability-loki-eks" 900 true false true

echo "5) Promtail"
apply_app_manifest "$OBS_APPS_DIR/app-observability-promtail-eks.yaml" "app-observability-promtail-eks"
wait_argocd_app_ready "app-observability-promtail-eks" 900 true false true

echo "6) OpenTelemetry Collector"
apply_app_manifest "$OBS_APPS_DIR/app-observability-otel-collector-eks.yaml" "app-otel-collector-eks"
wait_argocd_app_ready "app-otel-collector-eks" 900 true true true

echo "7) ConfigMap de datasource Tempo para Grafana"
kubectl apply -f "$OBS_CONFIGMAPS_DIR/grafana-tempo-datasource-eks.yaml"

echo "Resumen de aplicaciones de observabilidad"
kubectl get applications -n argocd | grep -E "observability|otel|NAME" || true

echo "Observabilidad EKS desplegada correctamente."
