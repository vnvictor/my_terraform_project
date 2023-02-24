variable "task_definition_info" {
  type = object({
    family = string
    container_image_name = string
    container_image = string
    cpu = number
    memory = number
    container_image_port = number
    requires_compatibilities = list(string)
    network_mode = string
    execution_role_arn = string
  })
}

variable "ecs_service_info" {
  type = object({
    name = string
    cluster_id = string
    launch_type = string
    desired_count = number

    load_balancer = object({
      target_group_arn = string
      container_image_name = string
      container_image_port = number
    })

    network_configuration = object({
      assign_public_ip = bool
      security_groups = list(string)
      subnets = list(string)
    })
  })
}