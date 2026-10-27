# -----------------------------------------------------------------------------
# Bootstrap - One-Time Setup
# Creates: S3 bucket for state, DynamoDB for locking, OIDC for GitHub Actions
#
# USAGE:
#   cd bootstrap
#   terraform init
#   terraform apply -var="github_org=YOUR_GITHUB_ORG" -var="github_repo=YOUR_REPO_NAME"
#
# Run this ONCE before using any environment. Apply manually with admin credentials.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Bootstrap uses LOCAL state (chicken-and-egg: can't use S3 before it exists)
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      Purpose   = "terraform-bootstrap"
    }
  }
}

data "aws_caller_identity" "current" {}

# =============================================================================
# S3 Bucket for Terraform State
# =============================================================================

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-state-${data.aws_caller_identity.current.account_id}"

  # Prevent accidental deletion of this bucket
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "Terraform State"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# =============================================================================
# DynamoDB Table for State Locking
# =============================================================================

resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform State Lock"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# =============================================================================
# GitHub OIDC Provider (for CI/CD — no long-lived AWS keys)
# =============================================================================

resource "aws_iam_openid_connect_provider" "github" {
  count = var.enable_github_oidc ? 1 : 0

  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = {
    Name = "GitHub Actions OIDC"
  }
}

# =============================================================================
# IAM Role for GitHub Actions
# =============================================================================

data "aws_iam_policy_document" "github_actions_assume" {
  count = var.enable_github_oidc ? 1 : 0

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github[0].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  count = var.enable_github_oidc ? 1 : 0

  name               = "github-actions-terraform"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume[0].json

  tags = {
    Name = "GitHub Actions Terraform Role"
  }
}

# Attach PowerUserAccess for Terraform operations
# NOTE: Scope this down in production to only the permissions Terraform needs
resource "aws_iam_role_policy_attachment" "github_actions" {
  count = var.enable_github_oidc ? 1 : 0

  role       = aws_iam_role.github_actions[0].name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# Allow IAM management (needed for Terraform to create roles, policies, etc.)
resource "aws_iam_role_policy" "github_actions_iam" {
  count = var.enable_github_oidc ? 1 : 0

  name = "iam-management"
  role = aws_iam_role.github_actions[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:PassRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:UpdateRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:GetInstanceProfile"
        ]
        Resource = "*"
      }
    ]
  })
}
