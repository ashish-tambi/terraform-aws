# -----------------------------------------------------------------------------
# Staging Environment - Main Configuration
# -----------------------------------------------------------------------------

module "networking" {
  source = "../../modules/networking"

  environment          = var.environment
  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
  enable_flow_logs     = var.enable_flow_logs

  tags = {
    CostCenter = "${var.project_name}-${var.environment}"
  }
}

module "compute" {
  source = "../../modules/compute"

  environment        = var.environment
  project_name       = var.project_name
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  public_subnet_ids  = module.networking.public_subnet_ids
  instance_type      = var.instance_type
  min_size           = var.min_size
  max_size           = var.max_size
  desired_capacity   = var.desired_capacity
  enable_alb         = var.enable_alb

  tags = {
    CostCenter = "${var.project_name}-${var.environment}"
  }
}
