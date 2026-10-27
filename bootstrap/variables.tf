# -----------------------------------------------------------------------------
# Bootstrap - Variables
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region for the state bucket and lock table"
  type        = string
  default     = "ap-south-1"
}

variable "enable_github_oidc" {
  description = "Whether to create GitHub OIDC provider and IAM role for CI/CD"
  type        = bool
  default     = true
}

variable "github_org" {
  description = "GitHub organization or username (e.g. 'my-company')"
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "GitHub repository name (e.g. 'aws-terraform')"
  type        = string
  default     = "aws-terraform"
}
