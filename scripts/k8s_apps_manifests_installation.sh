#!/bin/bash
# Variables inyectadas desde otros scripts:
# shellcheck disable=SC2154,SC1090
# - S3_Bucket_Name
# - K8S_S3_Manifests_Folder
# - initial_route_k8s_manifests
# - lib_file

source $lib_file

log "====== Empezamos k8s_apps_manifests_installation, descargamos archivos necesarios de S3 ======"
aws s3 cp s3://$S3_Bucket_Name/$K8S_S3_Manifests_Folder/deployment_blue.yaml $initial_route_k8s_manifests/deployment_blue.yaml
aws s3 cp s3://$S3_Bucket_Name/$K8S_S3_Manifests_Folder/deployment_green.yaml $initial_route_k8s_manifests/deployment_green.yaml
aws s3 cp s3://$S3_Bucket_Name/$K8S_S3_Manifests_Folder/service_blue.yaml $initial_route_k8s_manifests/service_blue.yaml
aws s3 cp s3://$S3_Bucket_Name/$K8S_S3_Manifests_Folder/service_green.yaml $initial_route_k8s_manifests/service_green.yaml

aws s3 cp s3://$S3_Bucket_Name/$K8S_S3_Manifests_Folder/ingress.yaml $initial_route_k8s_manifests/ingress.yaml

deployment_blue="$initial_route_k8s_manifests/deployment_blue.yaml"
deployment_green="$initial_route_k8s_manifests/deployment_green.yaml"
service_blue="$initial_route_k8s_manifests/service_blue.yaml"
service_green="$initial_route_k8s_manifests/service_green.yaml"

ingress="$initial_route_k8s_manifests/ingress.yaml"


log "Esperando a que AWS Load Balancer Controller Ready..."
kubectl --kubeconfig=/home/ec2-user/.kube/config wait --for=condition=ready pod \
    -l app.kubernetes.io/name=aws-load-balancer-controller \
    -n kube-system \
    --timeout=300s

log "Esperando a que el webhook tenga endpoints..."

while true; do
    ENDPOINTS=$(kubectl --kubeconfig=/home/ec2-user/.kube/config get endpointslice -n kube-system \
        -l kubernetes.io/service-name=aws-load-balancer-webhook-service \
        -o jsonpath='{.items[*].endpoints[*].addresses[*]}' 2>/dev/null)

    ENDPOINT_COUNT=$(echo "$ENDPOINTS" | wc -w)
    echo "Detected $ENDPOINT_COUNT endpoints"
    if [ "$ENDPOINT_COUNT" -gt 0 ]; then
        echo "Endpoints detectados: $ENDPOINT_COUNT IP(s)"
        echo "IPs: $ENDPOINTS"
        break
    fi

    echo "Esperando endpoints... (actualmente: 0)"
    sleep 5
done


kubectl --kubeconfig=/home/ec2-user/.kube/config patch mutatingwebhookconfiguration \
    aws-load-balancer-webhook --type='json' \
    -p='[{"op": "replace", "path": "/webhooks/1/timeoutSeconds", "value": 30}]' \
    2>/dev/null || log "Warning: No se pudo cambiar timeout del webhook"

log "Esperando 45s para estabilizacion del webhook..."
sleep 45

log "====== Ejecutamos manifests ======"
kubectl --kubeconfig=/home/ec2-user/.kube/config apply -f $deployment_blue
kubectl --kubeconfig=/home/ec2-user/.kube/config apply -f $deployment_green

kubectl --kubeconfig=/home/ec2-user/.kube/config apply -f $service_blue
kubectl --kubeconfig=/home/ec2-user/.kube/config apply -f $service_green

kubectl --kubeconfig=/home/ec2-user/.kube/config apply -f $ingress
