# -----------------------------------------------------------------------------
# Dev Environment - Variables
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region for this environment"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
}

# --- Networking ---

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT Gateway"
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Whether to enable VPC flow logs"
  type        = bool
  default     = false
}

# --- Compute ---

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "min_size" {
  description = "Minimum ASG size"
  type        = number
}

variable "max_size" {
  description = "Maximum ASG size"
  type        = number
}

variable "desired_capacity" {
  description = "Desired ASG capacity"
  type        = number
}

variable "enable_alb" {
  description = "Whether to create an ALB"
  type        = bool
  default     = true
}
