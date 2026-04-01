
resource "aws_launch_template" "test_server" {
  name_prefix   = "${var.cluster_name}-"
  image_id      = var.ami
  instance_type = var.instance_type

  network_interfaces {
    security_groups             = [aws_security_group.internet.id]
    associate_public_ip_address = true
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    DB_ADDRESS  = data.terraform_remote_state.db.outputs.address,
    DB_PORT     = data.terraform_remote_state.db.outputs.port,
    SERVER_PORT = var.server_port
    SERVER_TEXT = var.server_text
  }))
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "internet" {
  name = "${var.cluster_name}-internet"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_autoscaling_group" "server_increase" {
  # Explicitly depend on the launch templates name so each time it's replaced, this ASG is also replaced"
  name = "${var.cluster_name}-${aws_launch_template.test_server.latest_version}"

  min_size            = var.min_size
  max_size            = var.max_size
  vpc_zone_identifier = data.aws_subnets.default.ids

  # Wait for at least this many instances to pass health checks before considering the ASG deployment complete
  min_elb_capacity = var.min_size

  launch_template {
    id      = aws_launch_template.test_server.id
    version = "$Latest"
  }

  # When replacing this ASG, create the replacement first, and only delete the original after
  lifecycle {
    create_before_destroy = true
  }

  target_group_arns         = [aws_lb_target_group.asg.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 60

  capacity_rebalance = true

  tag {
    key                 = "Name"
    value               = var.cluster_name
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.custom_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  count                  = var.enable_autoscaling ? 1 : 0
  
  scheduled_action_name  = "${var.cluster_name}-scale-out-during-business-hours"
  min_size               = 2
  max_size               = 10
  desired_capacity       = 10
  recurrence             = "0 9 * * *"
  autoscaling_group_name = aws_autoscaling_group.scale_out_during_business_hours
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  count                  = var.enable_autoscaling ? 1 : 0

  scheduled_action_name  = "${var.cluster_name}-scale-in-at-night"
  min_size               = 2
  max_size               = 2
  desired_capacity       = 4
  recurrence             = "0 17 * * *"
  autoscaling_group_name = aws_autoscaling_group.scale-in-at-night
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}


resource "aws_lb" "load-balancer" {
  name               = "${var.cluster_name}-lb"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.load-balancer.arn
  port              = local.http_port
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404:page not found"
      status_code  = 404
    }
  }

}

resource "aws_security_group" "alb" {
  name = "${var.cluster_name}-alb"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.alb.id

  from_port   = local.http_port
  to_port     = local.http_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.alb.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips
}

resource "aws_lb_target_group" "asg" {
  name     = "${var.cluster_name}-tg-asg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}


data "terraform_remote_state" "db" {
  backend = "s3"

  config = {
    bucket = var.db_remote_state_bucket
    key    = var.db_remote_state_key
    region = "us-east-1"
  }
}

locals {
  http_port    = 80
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}

