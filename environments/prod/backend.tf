# -----------------------------------------------------------------------------
# Production Environment - Backend Configuration
# -----------------------------------------------------------------------------

terraform {
  backend "s3" {
    bucket         = "terraform-state-<ACCOUNT_ID>"
    key            = "environments/prod/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
