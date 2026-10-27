# -----------------------------------------------------------------------------
# Bootstrap - Outputs
# -----------------------------------------------------------------------------

output "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN of the S3 state bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

output "lock_table_name" {
  description = "Name of the DynamoDB lock table"
  value       = aws_dynamodb_table.terraform_lock.id
}

output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions (use in workflows)"
  value       = var.enable_github_oidc ? aws_iam_role.github_actions[0].arn : "OIDC not enabled"
}

output "account_id" {
  description = "AWS Account ID (use this to update backend.tf files)"
  value       = data.aws_caller_identity.current.account_id
}

output "next_steps" {
  description = "Instructions for next steps"
  value       = <<-EOT

    ✅ Bootstrap complete!

    Next steps:
    1. Replace <ACCOUNT_ID> in all backend.tf files with: ${data.aws_caller_identity.current.account_id}
    2. Add GitHub Actions secrets:
       - AWS_ROLE_ARN = ${var.enable_github_oidc ? aws_iam_role.github_actions[0].arn : "N/A"}
       - AWS_REGION   = ${var.aws_region}
    3. Initialize each environment:
       cd environments/dev && terraform init
       cd environments/staging && terraform init
       cd environments/prod && terraform init

  EOT
}
