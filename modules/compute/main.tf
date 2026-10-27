# -----------------------------------------------------------------------------
# Compute Module - Main Resources
# Security Groups, Launch Template, ASG, ALB
# -----------------------------------------------------------------------------

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  ami_id = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux.id

  common_tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project_name
    Module      = "compute"
  })
}

# =============================================================================
# Security Groups
# =============================================================================

resource "aws_security_group" "alb" {
  count = var.enable_alb ? 1 : 0

  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "app" {
  name        = "${var.project_name}-${var.environment}-app-sg"
  description = "Security group for application instances"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.enable_alb ? [1] : []
    content {
      description     = "Traffic from ALB"
      from_port       = var.app_port
      to_port         = var.app_port
      protocol        = "tcp"
      security_groups = [aws_security_group.alb[0].id]
    }
  }

  dynamic "ingress" {
    for_each = var.enable_alb ? [] : [1]
    content {
      description = "Direct traffic (no ALB)"
      from_port   = var.app_port
      to_port     = var.app_port
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-app-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# Launch Template
# =============================================================================

resource "aws_launch_template" "main" {
  name_prefix   = "${var.project_name}-${var.environment}-"
  image_id      = local.ami_id
  instance_type = var.instance_type

  key_name = var.key_name != "" ? var.key_name : null

  vpc_security_group_ids = [aws_security_group.app.id]

  # IMDSv2 required (security best practice)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  # Enable detailed monitoring in prod
  monitoring {
    enabled = var.environment == "prod"
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -euo pipefail

    # Log startup
    echo "Starting ${var.project_name} ${var.environment} instance" | tee /var/log/user-data.log

    # Install and start a basic web server for health checks
    yum install -y httpd
    echo "<h1>${var.project_name} - ${var.environment}</h1><p>Instance: $(hostname)</p>" > /var/www/html/index.html
    systemctl enable httpd
    systemctl start httpd
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${var.project_name}-${var.environment}-instance"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(local.common_tags, {
      Name = "${var.project_name}-${var.environment}-volume"
    })
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-lt"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# =============================================================================
# Application Load Balancer
# =============================================================================

resource "aws_lb" "main" {
  count = var.enable_alb ? 1 : 0

  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[0].id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.environment == "prod"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-alb"
  })
}

resource "aws_lb_target_group" "main" {
  count = var.enable_alb ? 1 : 0

  name     = "${var.project_name}-${var.environment}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    path                = var.health_check_path
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-tg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "http" {
  count = var.enable_alb ? 1 : 0

  load_balancer_arn = aws_lb.main[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main[0].arn
  }

  tags = local.common_tags
}

# =============================================================================
# Auto Scaling Group
# =============================================================================

resource "aws_autoscaling_group" "main" {
  name                = "${var.project_name}-${var.environment}-asg"
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.private_subnet_ids

  # Health check from ALB if enabled, otherwise EC2
  health_check_type         = var.enable_alb ? "ELB" : "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-asg"
    propagate_at_launch = false
  }

  dynamic "tag" {
    for_each = local.common_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = false
    }
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

# Attach ASG to ALB target group
resource "aws_autoscaling_attachment" "main" {
  count = var.enable_alb ? 1 : 0

  autoscaling_group_name = aws_autoscaling_group.main.id
  lb_target_group_arn    = aws_lb_target_group.main[0].arn
}

# =============================================================================
# Auto Scaling Policies (scale based on CPU)
# =============================================================================

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.project_name}-${var.environment}-scale-up"
  autoscaling_group_name = aws_autoscaling_group.main.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
  policy_type            = "SimpleScaling"
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.project_name}-${var.environment}-scale-down"
  autoscaling_group_name = aws_autoscaling_group.main.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 70

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_up.arn]

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 20

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.main.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_down.arn]

  tags = local.common_tags
}
