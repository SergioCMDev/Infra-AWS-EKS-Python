output "vpc_id" {
  value       = aws_vpc.vpc.id
  description = "VPC_ID"
}

output "public_subnets" {
  value       = join(",", aws_subnet.public_net[*].id)
  description = "public_subnets"
}

output "private_subnets" {
  value       = join(",", aws_subnet.private_net[*].id)
  description = "private_subnets"
}

output "alb_sg" {
  value       = aws_security_group.alb_access_sg.id
  description = "alb_sg"
}

output "ec2_sg" {
  value       = aws_security_group.ec2_sg.id
  description = "ec2_sg"
}

output "cluster_eks_sg" {
  value       = aws_security_group.cluster_eks.id
  description = "cluster_eks_sg"
}
