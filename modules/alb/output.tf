output "subnets" {
  value = aws_alb.app_load_balancer.subnets
}

output "target_group_arn" {
  value = aws_lb_target_group.target_group.arn
}