#!/bin/bash
set -e 

log(){
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a /var/log/k8s-init.log        
}


echo "====== Definimos variables ======"
RUNNER_VERSION=${runner_version}
S3_Bucket_Name=${s3_bucket_name}
REPO_NAME=${repo_name}
REPO_USER=${repo_user}
TOKEN=${token}
RUNNER_NAME=${runner_name}
RUNNER_LABELS=${runner_labels}
RUNNER_WORK_DIR="_work"

USER_EC2=ec2-user
export S3_Scripts_Folder="scripts"
export initial_route="/opt"

echo "====== Creating scripts folder ======"
mkdir -p $initial_route/$S3_Scripts_Folder

echo "====== Exportamos variables de Terraform ======"
base64 --decode <<< "${blue_green_updater_script}" > $initial_route/$S3_Scripts_Folder/blue_green_updater.sh
base64 --decode <<< "${configure_eks_script}" > $initial_route/$S3_Scripts_Folder/configure_eks_script.sh
sed -i 's/\r$//' $initial_route/$S3_Scripts_Folder/configure_eks_script.sh
sed -i 's/\r$//' $initial_route/$S3_Scripts_Folder/blue_green_updater.sh

chmod +x $initial_route/$S3_Scripts_Folder/*.sh

# log "====== Updating system ======"
# dnf update -y

# log "====== Updating OS ======"
# dnf upgrade -y --releasever=2023.9.20250929

sudo dnf install -y \
    git \
    wget \
    tar \
    gzip \
    jq \
    nano \
    perl-Digest-SHA \
    libicu \
    krb5-libs \
    zlib \
    openssl-libs \
    lttng-ust \
    docker \
    aws-cli

log "====== Installing Docker ======"
systemctl start docker
systemctl enable docker
usermod -aG docker $USER_EC2

log "====== Installing eksctl ======" #TEST
ARCH=amd64
PLATFORM=$(uname -s)_$ARCH
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp && rm eksctl_$PLATFORM.tar.gz
sudo install -m 0755 /tmp/eksctl /usr/local/bin && rm /tmp/eksctl


# log "====== Installing AWS CLI installed ======"
# curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
# unzip awscliv2.zip
# sudo ./aws/install
# rm -rf awscliv2.zip aws

log "====== Installing AWS IAM Authenticator ======"
curl -o /usr/local/bin/aws-iam-authenticator \
    https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/aws-iam-authenticator
chmod +x /usr/local/bin/aws-iam-authenticator

log "====== Downloading GitHub Actions Runner v$RUNNER_VERSION ======"
cd /home/$USER_EC2
mkdir -p actions-runner && cd actions-runner

curl -o actions-runner-linux-x64-$RUNNER_VERSION.tar.gz -L https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-linux-x64-$RUNNER_VERSION.tar.gz # Optional: Validate the hash
echo "194f1e1e4bd02f80b7e9633fc546084d8d4e19f3928a324d512ea53430102e1d  actions-runner-linux-x64-$RUNNER_VERSION.tar.gz" | shasum -a 256 -c # Extract the installer
       
log "====== Extracting GitHub Actions Runner  ======"
tar xzf ./actions-runner-linux-x64-$RUNNER_VERSION.tar.gz # Install dependencies
rm actions-runner-linux-x64-$RUNNER_VERSION.tar.gz

log "====== Changing ownership a actions-runner  ======"
chown -R $USER_EC2:$USER_EC2 /home/$USER_EC2/actions-runner

log "====== Installing dependencies ======"
sudo -u $USER_EC2 bash << EOSU
    cd /home/$USER_EC2/actions-runner

    ./config.sh --url https://github.com/$REPO_USER/$REPO_NAME \
        --token $TOKEN \
        --name "$RUNNER_NAME" \
        --labels "$RUNNER_LABELS" \
        --work "$RUNNER_WORK_DIR" \
        --unattended \
        --replace
EOSU

log "====== Installing GitHub Actions Runner service as Systemd service ======"
cd /home/$USER_EC2/actions-runner
./svc.sh install $USER_EC2
./svc.sh start

log "====== Checking status of GitHub Actions Runner service ======"
./svc.sh status

sudo systemctl enable actions.runner.*