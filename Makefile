# =============================================================================
# Terraform Makefile
# Convenience commands for local development
#
# Usage:
#   make dev-plan        Plan dev environment
#   make staging-apply   Apply staging environment
#   make prod-plan       Plan prod environment
#   make fmt             Format all Terraform files
#   make validate-all    Validate all environments
# =============================================================================

.PHONY: help fmt validate-all \
        dev-init dev-plan dev-apply dev-destroy dev-output \
        staging-init staging-plan staging-apply staging-destroy staging-output \
        prod-init prod-plan prod-apply prod-destroy prod-output \
        bootstrap-init bootstrap-apply

# Default target
help: ## Show this help
	@echo ""
	@echo "Available targets:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

# =============================================================================
# Global Commands
# =============================================================================

fmt: ## Format all Terraform files
	terraform fmt -recursive

validate-all: dev-validate staging-validate prod-validate ## Validate all environments

# =============================================================================
# Bootstrap
# =============================================================================

bootstrap-init: ## Initialize bootstrap
	cd bootstrap && terraform init

bootstrap-apply: ## Apply bootstrap (creates S3 bucket, DynamoDB, OIDC)
	cd bootstrap && terraform apply

# =============================================================================
# Dev Environment
# =============================================================================

dev-init: ## Initialize dev environment
	cd environments/dev && terraform init

dev-plan: ## Plan dev environment
	cd environments/dev && terraform plan

dev-apply: ## Apply dev environment
	cd environments/dev && terraform apply

dev-destroy: ## Destroy dev environment
	cd environments/dev && terraform destroy

dev-output: ## Show dev outputs
	cd environments/dev && terraform output

dev-validate: ## Validate dev config
	cd environments/dev && terraform validate

# =============================================================================
# Staging Environment
# =============================================================================

staging-init: ## Initialize staging environment
	cd environments/staging && terraform init

staging-plan: ## Plan staging environment
	cd environments/staging && terraform plan

staging-apply: ## Apply staging environment
	cd environments/staging && terraform apply

staging-destroy: ## Destroy staging environment
	cd environments/staging && terraform destroy

staging-output: ## Show staging outputs
	cd environments/staging && terraform output

staging-validate: ## Validate staging config
	cd environments/staging && terraform validate

# =============================================================================
# Prod Environment
# =============================================================================

prod-init: ## Initialize prod environment
	cd environments/prod && terraform init

prod-plan: ## Plan prod environment
	cd environments/prod && terraform plan

prod-apply: ## Apply prod environment (⚠️  PRODUCTION)
	@echo "⚠️  WARNING: Applying to PRODUCTION"
	@read -p "Type 'yes' to confirm: " confirm && [ "$$confirm" = "yes" ] || exit 1
	cd environments/prod && terraform apply

prod-destroy: ## Destroy prod environment (⚠️  PRODUCTION)
	@echo "⚠️  WARNING: Destroying PRODUCTION resources"
	@read -p "Type 'yes' to confirm: " confirm && [ "$$confirm" = "yes" ] || exit 1
	cd environments/prod && terraform destroy

prod-output: ## Show prod outputs
	cd environments/prod && terraform output

prod-validate: ## Validate prod config
	cd environments/prod && terraform validate
