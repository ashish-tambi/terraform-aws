# AWS Terraform — Multi-Environment Infrastructure

Production-grade Terraform repository for managing AWS infrastructure across **dev**, **staging**, and **prod** environments in a single AWS account.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      AWS Account                                │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │     DEV      │  │   STAGING    │  │     PROD     │          │
│  │              │  │              │  │              │          │
│  │  VPC 10.0.x  │  │  VPC 10.1.x  │  │  VPC 10.2.x  │          │
│  │  t3.micro    │  │  t3.small    │  │  t3.medium   │          │
│  │  1 instance  │  │  1-2 inst.   │  │  2-4 inst.   │          │
│  │  No NAT      │  │  NAT + ALB   │  │  NAT + ALB   │          │
│  │              │  │              │  │  Flow Logs   │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Shared: S3 State Bucket │ DynamoDB Lock │ OIDC Provider │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Repository Structure

```
aws-terraform/
├── modules/                        # Reusable Terraform modules
│   ├── networking/                  # VPC, subnets, IGW, NAT, route tables
│   └── compute/                    # EC2, ASG, ALB, security groups
├── environments/                   # Per-environment root configurations
│   ├── dev/                        # Development environment
│   ├── staging/                    # Staging environment
│   └── prod/                       # Production environment
├── bootstrap/                      # One-time setup (S3, DynamoDB, OIDC)
├── .github/workflows/              # CI/CD pipelines
│   ├── terraform-plan.yml          # Plan on PR
│   └── terraform-apply.yml         # Apply on merge to main
├── scripts/tf.sh                   # Helper script for local dev
├── Makefile                        # Convenience commands
├── CODEOWNERS                      # PR review requirements
└── .terraform-version              # Pinned Terraform version
```

## Quick Start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.5.7 (or use [tfenv](https://github.com/tfutils/tfenv))
- [AWS CLI](https://aws.amazon.com/cli/) configured with credentials
- Make (optional, for convenience commands)

### 1. Bootstrap (One-Time)

Creates the S3 bucket, DynamoDB table, and GitHub OIDC provider:

```bash
cd bootstrap

# Without GitHub OIDC (local-only)
terraform init
terraform apply

# With GitHub OIDC (for CI/CD)
terraform init
terraform apply \
  -var="github_org=YOUR_ORG" \
  -var="github_repo=aws-terraform"
```

After bootstrap completes, **update the `<ACCOUNT_ID>` placeholder** in all `environments/*/backend.tf` files with your actual AWS account ID (shown in the bootstrap output).

### 2. Initialize an Environment

```bash
cd environments/dev
terraform init
```

### 3. Plan & Apply

```bash
# Using the helper script
./scripts/tf.sh dev plan
./scripts/tf.sh dev apply

# Using Make
make dev-plan
make dev-apply

# Using Terraform directly
cd environments/dev
terraform plan
terraform apply
```

## Team Workflow (GitOps)

```
Feature Branch → Pull Request → Code Review → Merge to Main
                      │                              │
              (auto: terraform plan)         (auto: terraform apply)
              (posts plan as PR comment)     (dev → staging → prod)
```

### For Developers

1. Create a feature branch
2. Make changes to the relevant environment or module
3. Open a Pull Request → CI automatically runs `terraform plan`
4. Get the plan reviewed by your team
5. Merge → CI automatically applies changes (dev → staging → prod with manual approval for prod)

### Production Safety

- **CODEOWNERS**: Changes to `environments/prod/` and `modules/` require approval from team leads
- **GitHub Environment Protection**: Prod deploy requires manual approval in GitHub
- **Helper script**: `./scripts/tf.sh` prompts for confirmation before `apply`/`destroy` on prod
- **ALB deletion protection**: Enabled automatically for prod ALBs
- **State locking**: DynamoDB prevents concurrent applies from 10 team members

## CI/CD Setup (GitHub Actions)

### Required GitHub Configuration

1. **Repository Secrets**:
   - `AWS_ROLE_ARN` — The ARN from bootstrap output (e.g., `arn:aws:iam::123456789012:role/github-actions-terraform`)

2. **GitHub Environments** (Settings → Environments):
   - `dev` — No protection rules
   - `staging` — No protection rules
   - `production` — Add required reviewers (team leads)

3. **Branch Protection** (Settings → Branches → `main`):
   - ✅ Require pull request reviews
   - ✅ Require status checks (terraform-plan)
   - ✅ Require review from Code Owners

## Adding New Modules

1. Create a new directory under `modules/`:
   ```
   modules/database/
   ├── main.tf
   ├── variables.tf
   └── outputs.tf
   ```

2. Reference it from each environment's `main.tf`:
   ```hcl
   module "database" {
     source = "../../modules/database"
     environment  = var.environment
     project_name = var.project_name
     # ... module-specific vars
   }
   ```

3. Add environment-specific values to each `terraform.tfvars`

## Environment Comparison

| Feature | Dev | Staging | Prod |
|---|:---:|:---:|:---:|
| VPC CIDR | 10.0.0.0/16 | 10.1.0.0/16 | 10.2.0.0/16 |
| Instance Type | t3.micro | t3.small | t3.medium |
| ASG Min/Max | 1/1 | 1/2 | 2/4 |
| NAT Gateway | ❌ | ✅ | ✅ |
| VPC Flow Logs | ❌ | ❌ | ✅ |
| ALB Deletion Protection | ❌ | ❌ | ✅ |
| Detailed Monitoring | ❌ | ❌ | ✅ |
| Deploy Approval | Auto | Auto | Manual |

## Common Commands

```bash
# Format all files
make fmt

# Validate all environments
make validate-all

# Plan specific environment
make dev-plan
make staging-plan
make prod-plan

# View outputs
make dev-output

# Using helper script (equivalent)
./scripts/tf.sh dev plan
./scripts/tf.sh staging apply
./scripts/tf.sh prod output
```

## Cost Optimization Tips

- **Dev**: No NAT Gateway (~$32/month savings), single t3.micro
- **Staging**: NAT enabled but minimal instances
- **Prod**: Full setup with HA — consider Reserved Instances for cost savings
- Run `terraform destroy` on dev/staging environments after hours if not needed

## Security Features

- **IMDSv2 enforced** on all EC2 instances
- **S3 state bucket**: Versioned, KMS-encrypted, public access blocked
- **OIDC authentication**: No long-lived AWS credentials in CI/CD
- **VPC Flow Logs**: Enabled in production for network audit trail
- **Security Groups**: Least-privilege (ALB → App only, no direct public access to instances)