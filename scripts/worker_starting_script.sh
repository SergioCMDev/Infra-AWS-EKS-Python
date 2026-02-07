#!/bin/bash
# shellcheck disable=SC2154
set -e
# Variables inyectadas por Terraform:
# - kubernetes_version
# - s3_bucket_name
# - nlb_endpoint

export S3_Scripts_Folder="scripts"
export S3_Config_Files="k8s_config_files"
export K8S_S3_Manifests_Folder="k8s_manifests"
export S3_Bucket_Name=${s3_bucket_name}

export initial_route="/opt/k8s"
export initial_route_k8s_manifests="/opt/k8s/manifests"
export config_files_route="config_files"

export NLB_ENDPOINT=${nlb_endpoint}
export KUBERNETES_VERSION=${kubernetes_version}

mkdir -p $initial_route


echo "===== Empezamos worker starting script====="
aws s3 cp s3://$S3_Bucket_Name/$S3_Scripts_Folder/lib.sh $initial_route/$S3_Scripts_Folder/lib.sh
export lib_file="$initial_route/$S3_Scripts_Folder/lib.sh"
# shellcheck disable=SC1090
source $lib_file

log "====== Updating OS======"
dnf update -y

log "====== Upgrading OS======"
dnf upgrade -y --releasever=2023.9.20250929

dnf install -y iproute iptables

aws s3 cp s3://$S3_Bucket_Name/$S3_Scripts_Folder/k8s_basic_inst.sh $initial_route/$S3_Scripts_Folder/k8s_basic_inst.sh
aws s3 cp s3://$S3_Bucket_Name/$S3_Config_Files/kubelet-config.yaml /var/lib/kubelet/kubelet-config.yaml
k8s_basic_inst="$initial_route/$S3_Scripts_Folder/k8s_basic_inst.sh"
sudo chmod +x $k8s_basic_inst
sudo sed -i 's/\r$//' $k8s_basic_inst

log "===== Adding VXLAN and BR_Netfilter modules for Calico ====="
aws s3 cp s3://$S3_Bucket_Name/$S3_Config_Files/modules_to_install.conf /etc/modules-load.d/modules_to_install.conf
modprobe vxlan
modprobe br_netfilter
modprobe overlay
modprobe iptable_filter
modprobe iptable_nat
modprobe ip_tables

log "====== Configuring sysctl ======"
aws s3 cp s3://$S3_Bucket_Name/$S3_Config_Files/99-kubernetes-cri.conf /etc/sysctl.d/99-kubernetes-cri.conf
sysctl --system


log "====== Getting Private IP ======"
# private_ip=$(get_metadata "local-ipv4")
# export PRIVATE_IP=$private_ip
# IP_TO_CHECK=$(aws ssm get-parameter --name "master-ip" --with-decryption --query "Parameter.Value"  --output text)

log "====== Executing k8s_basic_inst ======"
$k8s_basic_inst

while ! wait_for_apiserver || ! wait_for_updated_ssm_data; do
    log "API server not ready yet or MASTER CERTS not OK, waiting 10 seconds..."
    sleep 10
done

TOKEN=$(aws ssm get-parameter --name "k8s-token" --with-decryption --query "Parameter.Value"  --output text)
# CERT_KEY=$(aws ssm get-parameter --name "k8s-cert-key" --with-decryption --query "Parameter.Value"  --output text)
# CA_HASH=$(aws ssm get-parameter --name "k8s-ca-hash" --with-decryption --query "Parameter.Value"  --output text)


# log "====== SSM Values ======"
# echo "TOKEN: $TOKEN"
# echo "CERT_KEY: $CERT_KEY"
# echo "CA_HASH: $CA_HASH"

kubeadm join $NLB_ENDPOINT:6443 --token $TOKEN --discovery-token-ca-cert-hash sha256:$CA_HASH
sudo cp /var/lib/kubelet/kubeadm-flags.env /var/lib/kubelet/kubeadm-flags.env.bak

EXISTING_ARGS=$(sed -n 's/^KUBELET_KUBEADM_ARGS=//p' /var/lib/kubelet/kubeadm-flags.env | tr -d '"')
NEW_ARGS="${EXISTING_ARGS} --config=/var/lib/kubelet/kubelet-config.yaml"
echo "KUBELET_KUBEADM_ARGS=\"${NEW_ARGS}\"" > /var/lib/kubelet/kubeadm-flags.env
log "====== Worker joined ======"
