#!/bin/bash
set -e

CLUSTER_NAME=mi-cluster
REGION=eu-west-3
VPC_ID=vpc-00ce1bd466148a401
ROL_GITHUB_RUNNER=ec2_github_runner_role

echo "Updating kubeconfig for cluster $CLUSTER_NAME in region $REGION"
aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION
helm repo add eks https://aws.github.io/eks-charts
helm repo update

echo "Installing AWS Load Balancer Controller via Helm"
helm install aws-load-balancer-controller eks/aws-load-balancer-controller   -n kube-system   --set clusterName=$CLUSTER_NAME   --set serviceAccount.create=true   --set serviceAccount.name=aws-load-balancer-controller   --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=arn:aws:iam::156041411098:role/aws-load-balancer-controller   --set region=$REGION   --set vpcId=$VPC_ID

sleep 15
echo "Applying Kubernetes manifests..."
kubectl apply -f k8s_manifests/deployment_blue.yaml
kubectl apply -f k8s_manifests/deployment_green.yaml
kubectl apply -f k8s_manifests/service_blue.yaml
kubectl apply -f k8s_manifests/service_green.yaml
kubectl apply -f k8s_manifests/ingress.yaml

echo "Mapping IAM role $ROL_GITHUB_RUNNER to Kubernetes user github-runner with system:masters group"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
eksctl create iamidentitymapping   --cluster $CLUSTER_NAME  \
 --region $REGION \
 --arn arn:aws:iam::$ACCOUNT_ID:role/$ROL_GITHUB_RUNNER  \
 --group system:masters  \
 --username github-runner
