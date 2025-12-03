#!/bin/bash
# set -xe 
export K8S_S3_Manifests_Folder="k8s_manifests"
export S3_Scripts_Folder="scripts"
export S3_Config_Files="k8s_config_files"

export initial_route="/opt/k8s"
export initial_route_k8s_manifests="/opt/k8s/manifests"
export config_files_route="config_files"

export S3_Bucket_Name=${s3_bucket_name}
export K8S_ROLE=${k8s_role}
export NLB_ENDPOINT=${nlb_endpoint}
export TARGET_GROUP_ARN=${target_group_arn}
export KUBERNETES_VERSION=${kubernetes_version}
export CLUSTER_NAME=${cluster_name}
export REGION=${region}
export VPC_ID=${vpcId}

mkdir -p $initial_route

echo "====== Empezamos control plane init, descargamos archivos necesarios de S3 ======"
aws s3 cp s3://$S3_Bucket_Name/$S3_Scripts_Folder/lib.sh $initial_route/$S3_Scripts_Folder/lib.sh 
export lib_file="$initial_route/$S3_Scripts_Folder/lib.sh"
source $lib_file

aws s3 cp s3://$S3_Bucket_Name/$S3_Config_Files/kubeadm_config.yaml $initial_route/$config_files_route/kubeadm_config.yaml
aws s3 cp s3://$S3_Bucket_Name/$S3_Scripts_Folder/k8s_basic_inst.sh $initial_route/$S3_Scripts_Folder/k8s_basic_inst.sh
aws s3 cp s3://$S3_Bucket_Name/$S3_Scripts_Folder/control-plane-k8s_installation.sh $initial_route/$S3_Scripts_Folder/control-plane-k8s_installation.sh
aws s3 cp s3://$S3_Bucket_Name/$S3_Scripts_Folder/k8s_apps_manifests_installation.sh $initial_route/$S3_Scripts_Folder/k8s_apps_manifests_installation.sh

kubeadm_config_file="$initial_route/$config_files_route/kubeadm_config.yaml"
control_plane_k8s_installation="$initial_route/$S3_Scripts_Folder/control-plane-k8s_installation.sh"
k8s_basic_inst="$initial_route/$S3_Scripts_Folder/k8s_basic_inst.sh"
k8s_apps_manifests_installation="$initial_route/$S3_Scripts_Folder/k8s_apps_manifests_installation.sh"

sudo chmod +x $control_plane_k8s_installation
sudo chmod +x $k8s_basic_inst
sudo chmod +x $k8s_apps_manifests_installation
sudo chmod 644 $kubeadm_config_file

sudo sed -i 's/\r$//' $control_plane_k8s_installation
sudo sed -i 's/\r$//' $control_plane_k8s_installation
sudo sed -i 's/\r$//' $k8s_basic_inst
sudo sed -i 's/\r$//' $lib_file


log "====== Getting Private IP ======"
private_ip=$(get_metadata "local-ipv4")
log "====== Getting Host name ======"
HOSTNAME=$(get_metadata "local-hostname")
export PRIVATE_IP=$private_ip


if [[ $K8S_ROLE == "init-master" ]]; then
    aws ssm put-parameter --name "master-ip" --type "SecureString" --value "$PRIVATE_IP" --overwrite
    aws ssm put-parameter --name "master_certs_ok" --type "String" --value "1" --overwrite
fi

log "HOSTNAME $HOSTNAME IP $PRIVATE_IP"

log "====== Adding Private IP and HostName ======"
#Replace __PRIVATE_IP__ in template to add private IP, as well as putting private Ip in controlPlaneEndpoint
sudo sed -i "s/__PRIVATE_IP__/$PRIVATE_IP/g" $kubeadm_config_file

sed -i "s/controlPlaneEndpoint: .*/controlPlaneEndpoint: \"$PRIVATE_IP:6443\"/" $kubeadm_config_file

#Replace __HOSTNAME__ in template to add HOSTNAME
sudo sed -i "s|__NODE_NAME__|$HOSTNAME|g" $kubeadm_config_file

log "====== Executing k8s_basic_inst ======"
$k8s_basic_inst

log "====== Executing control-plane-k8s_installation.sh ======"
$control_plane_k8s_installation  $kubeadm_config_file

if [[ $K8S_ROLE == "init-master" ]]; then
    log "====== Desplegando manifests desde S3 ======"
    $k8s_apps_manifests_installation
fi