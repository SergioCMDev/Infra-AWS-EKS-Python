resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids         = local.private_subnets
    security_group_ids = [local.cluster_sg]

    endpoint_public_access  = true
    endpoint_private_access = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]
}

resource "aws_eks_node_group" "workers" {
  cluster_name   = aws_eks_cluster.main.name
  node_role_arn  = aws_iam_role.ec2_workers_role.arn
  subnet_ids     = local.private_subnets
  instance_types = [var.instance_type]

  scaling_config {
    desired_size = 4
    min_size     = 1
    max_size     = 8
  }

  launch_template {
    id      = aws_launch_template.node_group.id
    version = "$Latest"
  }
}

resource "aws_launch_template" "node_group" {
  name_prefix = "eks-node-group-"

  vpc_security_group_ids = [
    local.ec2_sg,
  ]
}

//Comprobar version con
# aws eks describe-addon-versions \
#   --addon-name vpc-cni \
#   --kubernetes-version 1.32 \
#   --query "addons[].addonVersions[0].addonVersion" \
#   --output text
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "vpc-cni"
  addon_version               = "v1.20.4-eksbuild.1"
  resolve_conflicts_on_create = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.workers
  ]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.workers
  ]
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"

  depends_on = [
    aws_eks_node_group.workers
  ]
}
