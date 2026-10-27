# -----------------------------------------------------------------------------
# Dev Environment - Variable Values
# -----------------------------------------------------------------------------

aws_region   = "ap-south-1"
environment  = "dev"
project_name = "myapp"

# --- Networking ---
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
enable_nat_gateway   = false
enable_flow_logs     = false

# --- Compute ---
instance_type    = "t3.micro"
min_size         = 1
max_size         = 1
desired_capacity = 1
enable_alb       = true
