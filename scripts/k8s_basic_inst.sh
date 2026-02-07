#!/bin/bash
# Variables inyectadas desde otros scripts:
# shellcheck disable=SC2154,SC1090
# - lib_file
# - S3_Bucket_Name
# - S3_Config_Files
# - initial_route

source $lib_file

log "====== Starting k8s basic installation ======"

exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
sleep 30

set -xe

log "====== Disable swap ======"
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab

log "====== Disable SELinux ======"
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

log "======Load k8s kernel modules ======"
aws s3 cp s3://$S3_Bucket_Name/$S3_Config_Files/modules_to_install.conf /etc/modules-load.d/modules_to_install.conf
modprobe vxlan
modprobe br_netfilter
modprobe overlay

log "======sysctl settings ======"
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

log "======Configuring SYSCTL ======"
aws s3 cp s3://$S3_Bucket_Name/$S3_Config_Files/99-kubernetes-cri.conf /etc/sysctl.d/99-kubernetes-cri.conf
sysctl --system

log "======Updating system ======"
dnf update -y

log "======Updating OS ======"
dnf upgrade -y --releasever=2023.9.20250929

log "======Installing containerd ======"
dnf install -y containerd
systemctl enable --now containerd

log "======Configuring containerd ======"
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml

log "======Add Kubernetes repo for RPM ======"
aws s3 cp s3://$S3_Bucket_Name/$S3_Config_Files/kubernetes.repo /etc/yum.repos.d/kubernetes.repo

log "========= Copying crictl to allow download images from containerd endpoint ==========="
aws s3 cp s3://$S3_Bucket_Name/$S3_Config_Files/crictl.yaml /etc/crictl.yaml

log "========= Configuring systemd cgroup driver ==========="
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

log "========= Installing yq ========="
curl -L https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq
chmod +x /usr/local/bin/yq
yq --version

log "========= Installing K8s component ========="
dnf install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
systemctl start kubelet  && systemctl enable kubelet
kubeadm config images pull


log "======Adding private IP to kubelet...======"
log "KUBELET_EXTRA_ARGS=--node-ip=$PRIVATE_IP" > /etc/sysconfig/kubelet

log "======End of basic inst======"
