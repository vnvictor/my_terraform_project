resource "aws_appautoscaling_target" "ecs_target" {
  min_capacity       = 1
  max_capacity       = 2
  resource_id        = "service/${var.ecs_cluster_id}/${var.ecs_service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  role_arn           = var.iam_role_arn
}

resource "aws_appautoscaling_policy" "scaling_policy_cpu" {
  name               = "app_autoscaling_policy_cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = var.target_value_cpu
  }
}

resource "aws_appautoscaling_policy" "scaling_policy_memory" {
  name               = "app_autoscaling_policy_memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = var.target_value_memory
  }
}