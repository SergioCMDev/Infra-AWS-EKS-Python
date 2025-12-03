output "alb_sg" {
  description = "alb_sg"
  value       = aws_security_group.alb_access_sg.id
}

output "public_subnets" {
  description = "public_subnets"
  value       = join(",", aws_subnet.public_net[*].id)
}
output "aws_load_balancer_controller_role_arn" {
  value       = aws_iam_role.aws_load_balancer_controller.arn
  description = "ARN del IAM role para el AWS Load Balancer Controller"
}

output "VPC_ID" {
  description = "VPC_ID"
  value       = aws_vpc.vpc.id
}
