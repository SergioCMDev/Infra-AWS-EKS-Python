#!/bin/bash
CONFIG_FILE=$1
USER_EC2=ec2-user

source $lib_file
set -e

log "====== kubeadm init ======"
if [[ $K8S_ROLE == "init-master" ]]; then
    # aws s3 cp  s3://$S3_Bucket_Name/$K8S_S3_Manifests_Folder/calico_inst.yaml $initial_route_k8s_manifests/calico_inst.yaml
    # calico_inst="$initial_route_k8s_manifests/calico_inst.yaml"
    IP_TO_CHECK=$PRIVATE_IP
    log "Master Plane -- $NLB_ENDPOINT"
    INIT_OUTPUT=$(sudo kubeadm init --config=$CONFIG_FILE --upload-certs -v=5 2>&1)

    while ! wait_for_apiserver; do
        log "API server not ready yet waiting 10 seconds..."
        sleep 10
    done

    move_kubeconfig

    aws s3 cp /home/$USER_EC2/.kube/config s3://$S3_Bucket_Name/$S3_Config_Files/kubeconfig

    log "====== wait_for_nlb_healthy  ======"
    if wait_for_nlb_healthy; then
        log "====== Reconfiguring cluster to use NLB======"

        kubectl config set-cluster kubernetes --server=https://$NLB_ENDPOINT:6443
        
        log "====== Cluster successfully configured with HA endpoint ======"
    fi


    log "====== Getting TOKEN, CA_HASH & CERT_KEY FROM KUBEADM JOIN ======"
    TOKEN=$(echo "$INIT_OUTPUT" | grep "kubeadm join" | sed -n 's/.*--token \([^ ]*\).*/\1/p' | head -n1)
    CA_HASH=$(echo "$INIT_OUTPUT" | grep -A 1 "kubeadm join" | grep -o -- '--discovery-token-ca-cert-hash [^ ]*' | cut -d' ' -f2 | head -n1 |sed 's/sha256://')
    CERT_KEY=$(echo "$INIT_OUTPUT" | grep -A 2 "kubeadm join"| grep -o -- '--certificate-key [a-f0-9]*' | cut -d' ' -f2 | head -n1)


    log "====== ADD TOKEN, CERT_KEY & CA_HASH to SSM ======"
    aws ssm put-parameter --name "master_certs_ok" --type "String" --value "1" --overwrite

    aws ssm put-parameter --name "k8s-token" --type "SecureString"  --value "$TOKEN" --overwrite
    aws ssm put-parameter --name "k8s-cert-key" --type "SecureString" --value "$CERT_KEY" --overwrite  
    aws ssm put-parameter --name "k8s-ca-hash" --type "SecureString" --value "$CA_HASH" --overwrite

    aws ssm put-parameter --name "master_certs_ok" --type "String" --value "0" --overwrite

    log "====== Install Helm ======"
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    sudo chmod 700 get_helm.sh
    sudo ./get_helm.sh
    rm get_helm.sh
    
    log "====== Añadimos repos de Helm ======"
    helm repo add eks https://aws.github.io/eks-charts
    helm repo add kubelet-csr-approver https://postfinance.github.io/kubelet-csr-approver
    helm repo add jetstack https://charts.jetstack.io

    helm repo update
    until kubectl get nodes | awk 'NR>1 && $3=="<none>"' | grep -q "."; do
        echo "Esperando a que exista al menos algun nodo..."
        sleep 5
    done

    log "====== Download Flannel ======"
    curl -L "https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml" --create-dirs -o $initial_route_k8s_manifests/kube-flannel.yml
    kube_flannel=$initial_route_k8s_manifests/kube-flannel.yml
    log "====== Config Network Plugin = flannel ======"
    kubectl apply -f $kube_flannel


    # log "====== Config Network Plugin = calico ======"
    # kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/calico.yaml -n kube-system

    # log "====== Instalamos Configuracion Calico ======"
    # kubectl apply -f $calico_inst

    NUM_WORKERS=$(kubectl get nodes | awk 'NR>1 && $3=="<none>"' | wc -l) 
    log Num Workers: $NUM_WORKERS
    NUM_WORKERS_READY=$(kubectl get nodes | awk 'NR>1 && $3=="<none>" && $2=="Ready"' | wc -l)
    while [ "$NUM_WORKERS_READY" -lt "$NUM_WORKERS" ]; do
        echo "Num Workers Ready: $NUM_WORKERS_READY / $NUM_WORKERS"
        NUM_WORKERS=$(kubectl get nodes | awk 'NR>1 && $3=="<none>"' | wc -l) 

        NUM_WORKERS_READY=$(kubectl get nodes | awk 'NR>1 && $3=="<none>" && $2=="Ready"' | wc -l)
        log "Esperando a que todos los nodos workers estén Ready..."
        sleep 5
    done
    log "Num Workers Ready: $NUM_WORKERS_READY / $NUM_WORKERS"
    log "Todos los nodos workers Ready"

    log "====== Label workers nodes ======"
    worker_nodes=$(kubectl get nodes -o json | jq -r '.items[] | select(.metadata.labels."node-role.kubernetes.io/control-plane" | not) | .metadata.name')
    for node in $worker_nodes; do
        echo "Labeling worker node: $node"
        kubectl label node $node node-role.kubernetes.io/worker=""
    done
    

    log "====== Instalamos Cert-Manager ======"
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.0/cert-manager.yaml

    log "====== Instalamos Kubelet CSR Approver ======" #REFRACTOR CREANDO UN ARCHIVO
    helm install kubelet-csr-approver kubelet-csr-approver/kubelet-csr-approver -n kube-system \
      --set-string providerRegex="^ip-124-0-[0-9-]+\\.eu-west-3\\.compute\\.internal$" \
      --set providerIpPrefixes='124.0.3.0/24\,124.0.4.0/24' \
      --set maxExpirationSeconds='86400' \
      --set bypassDnsResolution='true'


    log "====== Instalamos AWS ALB Controller ======" #REFRACTOR CREANDO UN ARCHIVO
    helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \
    --set clusterName=$CLUSTER_NAME  \
    --set ingressClass=alb \
    --set region=$REGION  \
    --set vpcId=$VPC_ID  \
    --set serviceAccount.name=aws-load-balancer-controller \
    --set enableAdmissionWebhook=true
    log "====== ALB Instalado ======"

    # log "====== Instalamos AWS Gateway Controller ======"
    # helm install aws-gateway-controller aws/aws-gateway-controller -n kube-system

else
    log "====== Additional Control Plane ======"

    IP_TO_CHECK=$(aws ssm get-parameter --name "master-ip" --with-decryption --query "Parameter.Value"  --output text)

    while ! wait_for_apiserver || ! wait_for_updated_ssm_data; do
        log "API server not ready yet or MASTER CERTS not OK, waiting 10 seconds..."
        sleep 10
    done

    TOKEN=$(aws ssm get-parameter --name "k8s-token" --with-decryption --query "Parameter.Value"  --output text) 
    CERT_KEY=$(aws ssm get-parameter --name "k8s-cert-key" --with-decryption --query "Parameter.Value"  --output text) 
    CA_HASH=$(aws ssm get-parameter --name "k8s-ca-hash" --with-decryption --query "Parameter.Value"  --output text)  
       
    # log "====== SSM Values ======"
    # echo "TOKEN: $TOKEN"
    # echo "CERT_KEY: $CERT_KEY" 
    # echo "CA_HASH: $CA_HASH"
    
    kubeadm join $IP_TO_CHECK:6443 --token $TOKEN --discovery-token-ca-cert-hash sha256:$CA_HASH --control-plane --certificate-key $CERT_KEY --v=5
    log "====== Worker joined ======"

    move_kubeconfig

fi

log "====== Get nodes ======"
kubectl get nodes

log "====== Cluster Info ======"
kubectl cluster-info