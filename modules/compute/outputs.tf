# -----------------------------------------------------------------------------
# Compute Module - Outputs
# -----------------------------------------------------------------------------

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.main.arn
}

output "launch_template_id" {
  description = "ID of the launch template"
  value       = aws_launch_template.main.id
}

output "alb_dns_name" {
  description = "DNS name of the ALB (null if ALB disabled)"
  value       = var.enable_alb ? aws_lb.main[0].dns_name : null
}

output "alb_zone_id" {
  description = "Zone ID of the ALB (null if ALB disabled)"
  value       = var.enable_alb ? aws_lb.main[0].zone_id : null
}

output "alb_arn" {
  description = "ARN of the ALB (null if ALB disabled)"
  value       = var.enable_alb ? aws_lb.main[0].arn : null
}

output "target_group_arn" {
  description = "ARN of the target group (null if ALB disabled)"
  value       = var.enable_alb ? aws_lb_target_group.main[0].arn : null
}

output "app_security_group_id" {
  description = "ID of the application security group"
  value       = aws_security_group.app.id
}

output "alb_security_group_id" {
  description = "ID of the ALB security group (null if ALB disabled)"
  value       = var.enable_alb ? aws_security_group.alb[0].id : null
}
