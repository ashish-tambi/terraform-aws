# -----------------------------------------------------------------------------
# Networking Module - Variables
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

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
}

variable "availability_zones" {
  description = "List of availability zones to use. If empty, auto-selects."
  type        = list(string)
  default     = []
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT Gateway for private subnet internet access"
  type        = bool
  default     = false
}

variable "enable_flow_logs" {
  description = "Whether to enable VPC Flow Logs to CloudWatch"
  type        = bool
  default     = false
}

variable "flow_logs_retention_days" {
  description = "Number of days to retain VPC flow logs in CloudWatch"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
