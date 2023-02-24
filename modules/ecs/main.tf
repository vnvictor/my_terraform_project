resource "aws_ecs_task_definition" "task_definition" {
  family = var.task_definition_info.family
  cpu                 = var.task_definition_info.cpu
  memory              = var.task_definition_info.memory
  container_definitions = jsonencode([{
    name                = var.task_definition_info.container_image_name
    image               = var.task_definition_info.container_image
    cpu                 = var.task_definition_info.cpu
    memory              = var.task_definition_info.memory
    essential           = true
    portMappings = [{
      containerPort     = var.task_definition_info.container_image_port
    }]
  }])
  requires_compatibilities = var.task_definition_info.requires_compatibilities
  network_mode = var.task_definition_info.network_mode
  execution_role_arn = var.task_definition_info.execution_role_arn
}

resource "aws_ecs_service" "service" {
  name = var.ecs_service_info.name
  cluster = var.ecs_service_info.cluster_id
  task_definition = aws_ecs_task_definition.task_definition.arn
  launch_type = var.ecs_service_info.launch_type
  desired_count = var.ecs_service_info.desired_count

  load_balancer {
    target_group_arn = var.ecs_service_info.load_balancer.target_group_arn
    container_name = var.ecs_service_info.load_balancer.container_image_name
    container_port = var.ecs_service_info.load_balancer.container_image_port
  }

  network_configuration {
    assign_public_ip = var.ecs_service_info.network_configuration.assign_public_ip
    security_groups = var.ecs_service_info.network_configuration.security_groups
    subnets = var.ecs_service_info.network_configuration.subnets
  }

}