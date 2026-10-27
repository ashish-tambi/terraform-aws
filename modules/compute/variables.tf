# -----------------------------------------------------------------------------
# Compute Module - Variables
# -----------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Project name used for resource naming and tagging"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC to deploy into"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the ASG instances"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type for the launch template"
  type        = string
  default     = "t3.micro"
}

variable "min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 2
}

variable "desired_capacity" {
  description = "Desired number of instances in the ASG"
  type        = number
  default     = 1
}

variable "ami_id" {
  description = "AMI ID for the launch template. If empty, uses latest Amazon Linux 2023."
  type        = string
  default     = ""
}

variable "key_name" {
  description = "SSH key pair name. Leave empty to disable SSH access."
  type        = string
  default     = ""
}

variable "health_check_path" {
  description = "Health check path for the ALB target group"
  type        = string
  default     = "/"
}

variable "app_port" {
  description = "Port the application listens on"
  type        = number
  default     = 80
}

variable "enable_alb" {
  description = "Whether to create an Application Load Balancer"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
