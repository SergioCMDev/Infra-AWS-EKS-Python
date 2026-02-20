#!/bin/bash
# shellcheck disable=SC2154
set -e
# Variables inyectadas por Terraform:
# - cluster_name
# - region
# - vpc_id
# - aws_alb_iam_role
# - argocd_role_arn

CLUSTER_NAME=mi-cluster
AWS_REGION=eu-west-3
VPC_ID=vpc-0dd464545b31cc0df
AWS_ALB_IAM_ROLE=aws-load-balancer-controller
ARGOCD_ROLE_ARN=arn:aws:iam::156041411098:role/argocd_ecr_pull_role
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "script dir $SCRIPT_DIR"
if [ -z "$CLUSTER_NAME" ] || [ -z $AWS_REGION ]; then
    echo "Usage: needs Cluster name and region"
    exit 1
fi

echo "Configuring kubeconfig for cluster $CLUSTER_NAME in region $AWS_REGION"
aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION  \
  --kubeconfig ~/.kube/config

helm repo add eks https://aws.github.io/eks-charts
helm repo update

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
CONTEXT_ARN="arn:aws:eks:$AWS_REGION:$ACCOUNT_ID:cluster/$CLUSTER_NAME"

echo "Using context ARN: $CONTEXT_ARN"
kubectl config use-context $CONTEXT_ARN

echo "Installing ALB Controller in $CLUSTER_NAME with role $AWS_ALB_IAM_ROLE in region $AWS_REGION and VPC $VPC_ID ..."
chmod +x "$SCRIPT_DIR/install-aws-alb.sh"
bash "$SCRIPT_DIR/install-aws-alb.sh"

echo "Using IAM role for AWS Load Balancer Controller with name: $AWS_ALB_IAM_ROLE"
echo "Installing AWS Load Balancer Controller via Helm"

sleep 20
chmod +x "$SCRIPT_DIR/Applying-k8s-manifests.sh"
bash "$SCRIPT_DIR/Applying-k8s-manifests.sh"

echo "Installing ArgoCD"
chmod +x "$SCRIPT_DIR/install-argocd.sh"
bash "$SCRIPT_DIR/install-argocd.sh" $ARGOCD_ROLE_ARN
