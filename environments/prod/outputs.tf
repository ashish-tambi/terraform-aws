# -----------------------------------------------------------------------------
# Production Environment - Outputs
# -----------------------------------------------------------------------------

output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnet_ids
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.compute.alb_dns_name
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.compute.asg_name
}
