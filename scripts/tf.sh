#!/usr/bin/env bash
# =============================================================================
# Terraform Helper Script
# Simplifies running Terraform commands across environments
#
# Usage:
#   ./scripts/tf.sh <environment> <command> [args...]
#
# Examples:
#   ./scripts/tf.sh dev plan
#   ./scripts/tf.sh staging apply
#   ./scripts/tf.sh prod plan -target=module.networking
#   ./scripts/tf.sh dev init
#   ./scripts/tf.sh dev fmt
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Validate arguments
if [ $# -lt 2 ]; then
  echo -e "${RED}Error: Missing arguments${NC}"
  echo ""
  echo "Usage: $0 <environment> <command> [args...]"
  echo ""
  echo "Environments: dev, staging, prod"
  echo "Commands:     init, plan, apply, destroy, fmt, validate, output, console"
  echo ""
  echo "Examples:"
  echo "  $0 dev plan"
  echo "  $0 staging apply"
  echo "  $0 prod plan -target=module.networking"
  exit 1
fi

ENV=$1
COMMAND=$2
shift 2
EXTRA_ARGS=("$@")

# Validate environment
if [[ ! "$ENV" =~ ^(dev|staging|prod)$ ]]; then
  echo -e "${RED}Error: Invalid environment '${ENV}'${NC}"
  echo "Valid environments: dev, staging, prod"
  exit 1
fi

# Set working directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_DIR="${PROJECT_ROOT}/environments/${ENV}"

if [ ! -d "$ENV_DIR" ]; then
  echo -e "${RED}Error: Environment directory not found: ${ENV_DIR}${NC}"
  exit 1
fi

echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}  Environment: ${YELLOW}${ENV}${NC}"
echo -e "${CYAN}  Command:     ${GREEN}terraform ${COMMAND} ${EXTRA_ARGS[*]:-}${NC}"
echo -e "${CYAN}  Directory:   ${ENV_DIR}${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Safety check for prod
if [ "$ENV" = "prod" ] && [[ "$COMMAND" =~ ^(apply|destroy)$ ]]; then
  echo -e "${YELLOW}⚠️  WARNING: You are about to ${COMMAND} PRODUCTION resources!${NC}"
  echo ""
  read -p "Type 'yes' to confirm: " CONFIRM
  if [ "$CONFIRM" != "yes" ]; then
    echo -e "${RED}Aborted.${NC}"
    exit 1
  fi
  echo ""
fi

# Execute terraform
cd "$ENV_DIR"

case "$COMMAND" in
  init)
    terraform init "${EXTRA_ARGS[@]:-}"
    ;;
  plan)
    terraform plan -var-file=terraform.tfvars "${EXTRA_ARGS[@]:-}"
    ;;
  apply)
    terraform apply -var-file=terraform.tfvars "${EXTRA_ARGS[@]:-}"
    ;;
  destroy)
    terraform destroy -var-file=terraform.tfvars "${EXTRA_ARGS[@]:-}"
    ;;
  fmt)
    cd "$PROJECT_ROOT"
    terraform fmt -recursive
    ;;
  validate)
    terraform validate "${EXTRA_ARGS[@]:-}"
    ;;
  output)
    terraform output "${EXTRA_ARGS[@]:-}"
    ;;
  console)
    terraform console "${EXTRA_ARGS[@]:-}"
    ;;
  *)
    terraform "$COMMAND" "${EXTRA_ARGS[@]:-}"
    ;;
esac

echo ""
echo -e "${GREEN}✅ Done!${NC}"
