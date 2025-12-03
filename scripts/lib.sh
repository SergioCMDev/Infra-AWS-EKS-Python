#!/bin/bash

set -u 

get_metadata() {
    local path="$1"
    local token
    
    # Obtener token de sesión
    token=$(curl -X PUT -s \
        "http://169.254.169.254/latest/api/token" \
        -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" \
        --connect-timeout 5 --max-time 10)
    
    if [ $? -ne 0 ] || [ -z "$token" ]; then
        echo "ERROR: No se pudo obtener token de metadatos" >&2
        return 1
    fi
    
    # Usar token para obtener metadatos
    curl -s -H "X-aws-ec2-metadata-token: $token" \
        "http://169.254.169.254/latest/meta-data/$path" \
        --connect-timeout 5 --max-time 10
}


log(){
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a /var/log/k8s-init.log        
}

wait_for_apiserver() {
    for i in {1..100}; do
        if curl -k https://$IP_TO_CHECK:6443/livez >/dev/null 2>&1; then
            echo "API server ready"
            return 0
        fi
        sleep 10
    done
    return 1
}

wait_for_updated_ssm_data() {
    for i in {1..100}; do
        local MASTER_CERTS_OK=$(aws ssm get-parameter --name "master_certs_ok" --query "Parameter.Value"  --output text)

        if [ "$MASTER_CERTS_OK" -eq 0 ]; then
            echo "MASTER CERTS OK"
            return 0
        fi
        sleep 10
    done
    return 1
}


move_kubeconfig(){
    log "====== move_kubeconfig ======"

    local USER_EC2=ec2-user
    local HOME_EC2=/home/$USER_EC2

    echo "HOME2 $HOME_EC2"
    sudo -u $USER_EC2 mkdir -p $HOME_EC2/.kube
    sudo cp -f /etc/kubernetes/admin.conf $HOME_EC2/.kube/config
    sudo chown $USER_EC2:$USER_EC2 $HOME_EC2/.kube/config
    export KUBECONFIG=$HOME_EC2/.kube/config
    echo 'export KUBECONFIG=~/.kube/config' | sudo tee -a /home/$USER_EC2/.bashrc
}

wait_for_nlb_healthy() {

    for i in {1..60}; do  # 30 minutos
        if aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN | grep -q "healthy"; then
            echo "NLB targets are healthy"
                return 0
        fi
        sleep 30
    done
    return 1
}