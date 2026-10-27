# -----------------------------------------------------------------------------
# Production Environment - Variable Values
# Production-grade: NAT, flow logs, multi-AZ, higher capacity
# -----------------------------------------------------------------------------

aws_region   = "ap-south-1"
environment  = "prod"
project_name = "myapp"

# --- Networking ---
vpc_cidr             = "10.2.0.0/16"
public_subnet_cidrs  = ["10.2.1.0/24", "10.2.2.0/24"]
private_subnet_cidrs = ["10.2.10.0/24", "10.2.11.0/24"]
enable_nat_gateway   = true
enable_flow_logs     = true

# --- Compute ---
instance_type    = "t3.medium"
min_size         = 2
max_size         = 4
desired_capacity = 2
enable_alb       = true
