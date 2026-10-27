# -----------------------------------------------------------------------------
# Staging Environment - Variable Values
# -----------------------------------------------------------------------------

aws_region   = "ap-south-1"
environment  = "staging"
project_name = "myapp"

# --- Networking ---
vpc_cidr             = "10.1.0.0/16"
public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs = ["10.1.10.0/24", "10.1.11.0/24"]
enable_nat_gateway   = true
enable_flow_logs     = false

# --- Compute ---
instance_type    = "t3.small"
min_size         = 1
max_size         = 2
desired_capacity = 1
enable_alb       = true
