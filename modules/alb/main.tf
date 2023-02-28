resource "aws_alb" "app_load_balancer" {
  name = var.name
  internal = var.is_internal
  load_balancer_type = var.lb_type
  security_groups = var.security_group_ids
  subnets = var.alb_subnets
  
}

resource "aws_lb_target_group" "target_group" {
  name        = var.target_group_info.name
  port        = var.target_group_info.port
  protocol    = var.target_group_info.protocol
  target_type = var.target_group_info.target_type
  vpc_id      = var.target_group_info.vpc_id

  health_check {
    enabled = var.target_group_info.is_enable
    path = var.target_group_info.health_check_path
  }
}

resource "aws_alb_listener" "http_listener" {
  load_balancer_arn = aws_alb.app_load_balancer.arn
  port = "8080"
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

