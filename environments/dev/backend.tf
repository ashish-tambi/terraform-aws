# -----------------------------------------------------------------------------
# Dev Environment - Backend Configuration
# Remote state stored in S3 with DynamoDB locking
# -----------------------------------------------------------------------------

terraform {
  backend "s3" {
    bucket         = "terraform-state-<ACCOUNT_ID>"
    key            = "environments/dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
